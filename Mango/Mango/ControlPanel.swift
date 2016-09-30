//
//  ControlPanel.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import SpeechToTextV1
import TextToSpeechV1
import LanguageTranslatorV2
import AVFoundation

protocol ControlPanelDelegate {
    func didClickedActionButton()
    func capturedSpeech(text: String)
    func translatedSpeech(text: String)
}

class ControlPanel: UIViewController {

    var recorder: AVAudioRecorder!
    var captureSession: AVCaptureSession?
    var stt: SpeechToText? = nil
    var tts: TextToSpeech? = nil
    var translator: LanguageTranslator? = nil
    var player: AVAudioPlayer? = nil
    var isStreaming = false
    var stopStreaming: (Void -> Void)? = nil
    var delegate: ControlPanelDelegate?
    
    @IBOutlet weak var actionButton: CircleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSessionAndRecorder()
        
        instantiateSTT()
        instantiatTranslator()
    }
    
    @IBAction func actionButtonClicked(sender: AnyObject) {
        startStopStreaming()
        startStopRecording()
        self.delegate?.didClickedActionButton()
    }
    
    private func setupSessionAndRecorder() {
        // create file to store recordings
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                            .UserDomainMask, true)[0]
        let filename = "SpeechToTextRecording.wav"
        let filepath = NSURL(fileURLWithPath: documents + "/" + filename)
        
        // set up session and recorder
        let session = AVAudioSession.sharedInstance()
        var settings = [String: AnyObject]()
        settings[AVSampleRateKey] = NSNumber(float: 44100.0)
        settings[AVNumberOfChannelsKey] = NSNumber(int: 1)
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            recorder = try AVAudioRecorder(URL: filepath, settings: settings)
        } catch {
            failure("Audio Recording", message: "Error setting up session/recorder.")
        }
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("AVAudioRecorder", message: "Could not set up recorder.")
            return
        }
        
        // prepare recorder to record
        recorder.delegate = self
        recorder.meteringEnabled = true
        recorder.prepareToRecord()
        
        // create capture session
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            return
        }
        
        // set microphone as a capture session input
        let microphoneDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
    }
    
    private func instantiateSTT() {
        // identify credentials file
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let credentialsURL = bundle.pathForResource("Credentials", ofType: "plist") else {
            failure("Loading Credentials", message: "Unable to locate credentials file.")
            return
        }
        
        // load credentials file
        let dict = NSDictionary(contentsOfFile: credentialsURL)
        guard let credentials = dict as? Dictionary<String, String> else {
            failure("Loading Credentials", message: "Unable to read credentials file.")
            return
        }
        
        // read SpeechToText username
        guard let user = credentials["SpeechToTextUsername"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text username.")
            return
        }
        
        // read SpeechToText password
        guard let password = credentials["SpeechToTextPassword"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text password.")
            return
        }
        
        stt = SpeechToText(username: user, password: password)
    }
    
    @IBAction func playButtonclicked(sender: AnyObject) {
        print(#function)
        self.playRecording()
    }
    
    
    func translate(text: String, success: LanguageTranslatorV2.TranslateResponse -> Void) {
        let failure = { (error: NSError) in print(error) }
        translator!.translate(text, modelID: "zh-en-patent", failure: failure, success: success)
    }
    
    func textToSpeech(text: String) {
        print(#function)
        guard let tts  = tts else {
            self.failure("TTS", message: "TextToSpeech not properly set up.")
            return
        }
        
        let failure = { (error: NSError) in print(error) }
        tts.synthesize(text, voice: SynthesisVoice.US_Allison, failure: failure) { data in
            do {
                self.player = try AVAudioPlayer(data: data)
                self.player?.play()
            } catch {
                self.failure("textToSpeech", message: "Error creating audio player.")
            }
        }
    }
    
    private func startStopStreaming() {
        print(#function)
        // stop if already streaming
        if (isStreaming) {
            captureSession?.stopRunning()
            stopStreaming?()
//            startStopStreamingCustomButton.setTitle("Start Streaming (Custom)", forState: .Normal)
            isStreaming = false
            return
        }
        
        // set streaming
        isStreaming = true
        
        // change button title
//        startStopStreamingCustomButton.setTitle("Stop Streaming (Custom)", forState: .Normal)
        
        // ensure SpeechToText service is up
        guard let stt = stt else {
            failure("STT Streaming", message: "SpeechToText not properly set up.")
            return
        }
        
        // ensure there is at least one audio input device available
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
        guard !devices.isEmpty else {
            let domain = "swift.ViewController"
            let code = -1
            let description = "Unable to access the microphone."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            failureStreaming(error)
            return
        }
        
        // create capture session
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            return
        }
        
        // add microphone as input to capture session
        let microphoneDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        // configure settings for streaming
        var settings = TranscriptionSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = true
        settings.interimResults = true
        settings.model = "zh-CN_BroadbandModel" //TODO: this should be configurable
        settings.inactivityTimeout = 60
        
        // create a transcription output
        let outputOpt = stt.createTranscriptionOutput(settings, failure: failureStreaming) {
            results in
            self.showResults(results)
        }
        
        // access tuple elements
        guard let output = outputOpt else {
            isStreaming = false
//            startStopStreamingCustomButton.setTitle("Start Streaming (Custom)", forState: .Normal)
            return
        }
        let transcriptionOutput = output.0
        stopStreaming = output.1
        
        // add transcription output to capture session
        if captureSession.canAddOutput(transcriptionOutput) {
            captureSession.addOutput(transcriptionOutput)
        }
        
        // start streaming
        captureSession.startRunning()
    }
    
    private func startStopRecording() {
        print(#function)
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Start/Stop Recording", message: "Recorder not properly set up.")
            return
        }
        
        // stop playing previous recording
        if let player = player {
            if (player.playing) {
                player.stop()
            }
        }
        
        // start/stop recording
        if (!recorder.recording) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setActive(true)
                recorder.record()
                actionButton.backgroundColor = UIColor.redColor()
                //                startStopRecordingButton.setTitle("Stop Recording", forState: .Normal)
                //                playRecordingButton.enabled = false
                //                transcribeButton.enabled = false
            } catch {
                failure("Start/Stop Recording", message: "Error setting session active.")
            }
        } else {
            do {
                recorder.stop()
                let session = AVAudioSession.sharedInstance()
                player?.stop()
                player?.prepareToPlay()
                try session.setActive(false)
                actionButton.backgroundColor = UIColor.greenColor()
                //                startStopRecordingButton.setTitle("Start Recording", forState: .Normal)
                //                playRecordingButton.enabled = true
                //                transcribeButton.enabled = true
            } catch {
                failure("Start/Stop Recording", message: "Error setting session inactive.")
            }
        }
    }
    
    private func failure(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    private func failureData(error: NSError) {
        let title = "Speech to Text Error:\nTranscribe"
        let message = error.localizedDescription
        failure(title, message: message)
    }
    
    private func failureStreaming(error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Custom)"
        let message = error.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            //            self.startStopStreamingCustomButton.enabled = true
            //            self.startStopStreamingCustomButton.setTitle("Start Streaming (Custom)",
            //                                                         forState: .Normal)
            self.isStreaming = false
        }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    private func titleCase(s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercaseString
        return first + String(s.characters.dropFirst())
    }
    
    private func showResults(results: [TranscriptionResult]) {
        var text = ""
        
        for result in results {
            if let transcript = result.alternatives.last?.transcript where result.final == true {
                let title = titleCase(transcript)
                text += String(title.characters.dropLast()) + "." + " "
            }
        }
        
        var txt = ""
        if results.last?.final == false {
            if let transcript = results.last?.alternatives.last?.transcript {
                txt = titleCase(transcript)
            }
        }
        print(text)
        if txt.isEmpty == false {
            translate(txt) { (response) in
                if let translated = response.translations.last {
                    self.delegate?.translatedSpeech(translated.translation);
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ControlPanel: AVAudioRecorderDelegate {
    
    private func transcribe(url: NSURL) {
        // ensure SpeechToText service is set up
        guard let stt = stt else {
            failure("Transcribe", message: "SpeechToText not properly set up.")
            return
        }
        
        // load data from saved recording
        guard let data = NSData(contentsOfURL: url) else {
            failure("Transcribe", message: "Error retrieving saved recording data.")
            return
        }
        
        // transcribe recording
        let settings = TranscriptionSettings(contentType: .WAV)
        stt.transcribe(data, settings: settings, failure: failureData) { results in
            self.showResults(results)
        }
    }
    
    private func playRecording() {
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Play Recording", message: "Recorder not properly set up")
            return
        }
        
        // play saved recording
        if (!recorder.recording) {
            do {
                player = try AVAudioPlayer(contentsOfURL: recorder.url)
                player?.play()
            } catch {
                failure("Play Recording", message: "Error creating audio player.")
            }
        }
    }
    
}

//TTS
extension ControlPanel {
    
    private func instantiateTTS() {
        // identify credentials file
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let credentialsURL = bundle.pathForResource("Credentials", ofType: "plist") else {
            failure("Loading Credentials", message: "Unable to locate credentials file.")
            return
        }
        
        // load credentials file
        let dict = NSDictionary(contentsOfFile: credentialsURL)
        guard let credentials = dict as? Dictionary<String, String> else {
            failure("Loading Credentials", message: "Unable to read credentials file.")
            return
        }
        
        // read SpeechToText username
        guard let user = credentials["TextToSpeechUsername"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text username.")
            return
        }
        
        // read SpeechToText password
        guard let password = credentials["TextToSpeechPassword"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text password.")
            return
        }
        
        tts = TextToSpeech(username: user, password: password)
    }

}

extension ControlPanel {
    private func instantiatTranslator() {
        // identify credentials file
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let credentialsURL = bundle.pathForResource("Credentials", ofType: "plist") else {
            failure("Loading Credentials", message: "Unable to locate credentials file.")
            return
        }
        
        // load credentials file
        let dict = NSDictionary(contentsOfFile: credentialsURL)
        guard let credentials = dict as? Dictionary<String, String> else {
            failure("Loading Credentials", message: "Unable to read credentials file.")
            return
        }
        
        // read SpeechToText username
        guard let user = credentials["LanguageTranslationUsername"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text username.")
            return
        }
        
        // read SpeechToText password
        guard let password = credentials["LanguageTranslationPassword"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text password.")
            return
        }
        
        translator = LanguageTranslator(username: user, password: password)
    }
}
