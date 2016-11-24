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
    func capturedSpeech(_ text: String)
    func translatedSpeech(_ text: String)
}

class ControlPanel: UIViewController {

    var recorder: AVAudioRecorder!
    var captureSession: AVCaptureSession?
    var stt: SpeechToText? = nil
    var tts: TextToSpeech? = nil
    var translator: LanguageTranslator? = nil
    var player: AVAudioPlayer? = nil
    var isStreaming = false
    var stopStreaming: ((Void) -> Void)? = nil
    var delegate: ControlPanelDelegate?
    
    @IBOutlet weak var actionButton: CircleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSessionAndRecorder()
        
        instantiateSTT()
        instantiatTranslator()
    }
    
    @IBAction func actionButtonClicked(_ sender: AnyObject) {
        startStopStreaming()
        startStopRecording()
        self.delegate?.didClickedActionButton()
    }
    
    fileprivate func setupSessionAndRecorder() {
        // create file to store recordings
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                            .userDomainMask, true)[0]
        let filename = "SpeechToTextRecording.wav"
        let filepath = URL(fileURLWithPath: documents + "/" + filename)
        
        // set up session and recorder
        let session = AVAudioSession.sharedInstance()
        var settings = [String: AnyObject]()
        settings[AVSampleRateKey] = NSNumber(value: 44100.0 as Float)
        settings[AVNumberOfChannelsKey] = NSNumber(value: 1 as Int32)
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            recorder = try AVAudioRecorder(url: filepath, settings: settings)
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
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        
        // create capture session
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            return
        }
        
        // set microphone as a capture session input
        let microphoneDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
    }
    
    fileprivate func instantiateSTT() {
        // identify credentials file
        let bundle = Bundle(for: type(of: self))
        guard let credentialsURL = bundle.path(forResource: "Credentials", ofType: "plist") else {
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
    
    @IBAction func playButtonclicked(_ sender: AnyObject) {
        print(#function)
        self.playRecording()
    }
    
    
    func translate(_ text: String, success: (LanguageTranslatorV2.TranslateResponse) -> Void) {
//        let failure = { (error: Error) in print(error) }
//        translator!.translate(text, withModelID: "zh-en-patent", failure: failure, success: success)
    }
    
    func textToSpeech(_ text: String) {
        print(#function)
        guard let tts  = tts else {
            self.failure("TTS", message: "TextToSpeech not properly set up.")
            return
        }
        
        let failure = { (error: Error) in print(error) }
        
        tts.synthesize(text, voice: SynthesisVoice.us_Allison.rawValue, failure: failure) { data in
            do {
                self.player = try AVAudioPlayer(data: data)
                self.player?.play()
            } catch {
                self.failure("textToSpeech", message: "Error creating audio player.")
            }
        }
    }
    
    fileprivate func startStreaming() {
        guard let stt = stt else {
            return
        }
        
        var settings = RecognitionSettings(contentType: .opus)
        settings.continuous = true
        settings.interimResults = true
        let failure = { (error: Error) in print(error) }
        let _ = stt.recognizeMicrophone(settings: settings, failure: failure) { results in
            print(results.bestTranscript)
        }
    }
    
    fileprivate func stopStreaming1() {
        stt?.stopRecognizeMicrophone()
    }
    
    //
    fileprivate func startStopStreaming() {
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
            return
        }
        
        // ensure there is at least one audio input device available
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio)
        guard !(devices?.isEmpty)! else {
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
        let microphoneDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        // define recognition request settings
        var settings = RecognitionSettings(contentType: .opus)
        settings.interimResults = true
        settings.continuous = true
        
        let failure = { (error: Error) in print(error) }
        let _ = stt.recognizeMicrophone(settings: settings, failure: failure) { results in
            print(results.bestTranscript)
        }
        
        // start streaming
        captureSession.startRunning()
    }
    
    fileprivate func startStopRecording() {
        print(#function)
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Start/Stop Recording", message: "Recorder not properly set up.")
            return
        }
        
        // stop playing previous recording
        if let player = player {
            if (player.isPlaying) {
                player.stop()
            }
        }
        
        // start/stop recording
        if (!recorder.isRecording) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setActive(true)
                recorder.record()
                actionButton.backgroundColor = UIColor.red
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
                actionButton.backgroundColor = UIColor.green
                //                startStopRecordingButton.setTitle("Start Recording", forState: .Normal)
                //                playRecordingButton.enabled = true
                //                transcribeButton.enabled = true
            } catch {
                failure("Start/Stop Recording", message: "Error setting session inactive.")
            }
        }
    }
    
    fileprivate func failure(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { action in }
        alert.addAction(ok)
        present(alert, animated: true) { }
    }
    
    fileprivate func failureData(_ error: NSError) {
        let title = "Speech to Text Error:\nTranscribe"
        let message = error.localizedDescription
        failure(title, message: message)
    }
    
    fileprivate func failureStreaming(_ error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Custom)"
        let message = error.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            //            self.startStopStreamingCustomButton.enabled = true
            //            self.startStopStreamingCustomButton.setTitle("Start Streaming (Custom)",
            //                                                         forState: .Normal)
            self.isStreaming = false
        }
        alert.addAction(ok)
        present(alert, animated: true) { }
    }
    
    fileprivate func titleCase(_ s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercased()
        return first + String(s.characters.dropFirst())
    }
    
    fileprivate func showResults(_ results: [SpeechRecognitionResult]) {
        var text = ""
        
        for result in results {
            if let transcript = result.alternatives.last?.transcript, result.final == true {
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
    
    fileprivate func transcribe(_ url: URL) {
        // ensure SpeechToText service is set up
        guard let stt = stt else {
            return
        }
        
        // load data from saved recording
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        
        var settings = RecognitionSettings(contentType: .wav)
        settings.interimResults = true
        
        stt.recognize(audio: data, settings: settings) { (results) in
            self.showResults(results.results)
        }
       
    }
    
    fileprivate func playRecording() {
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Play Recording", message: "Recorder not properly set up")
            return
        }
        
        // play saved recording
        if (!recorder.isRecording) {
            do {
                player = try AVAudioPlayer(contentsOf: recorder.url)
                player?.play()
            } catch {
                failure("Play Recording", message: "Error creating audio player.")
            }
        }
    }
    
}

//TTS
extension ControlPanel {
    
    fileprivate func instantiateTTS() {
        // identify credentials file
        let bundle = Bundle(for: type(of: self))
        guard let credentialsURL = bundle.path(forResource: "Credentials", ofType: "plist") else {
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
    
    fileprivate func instantiatTranslator() {
        // identify credentials file
        let bundle = Bundle(for: type(of: self))
        guard let credentialsURL = bundle.path(forResource: "Credentials", ofType: "plist") else {
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
