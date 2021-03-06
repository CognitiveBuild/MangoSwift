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

    @IBOutlet weak var waveTimeView: WaveTimeView!
    var audioService: IAudioService!
    var audioFilePath: URL!
    
    var speechToText: SpeechToText!
    var speechToTextSession: SpeechToTextSession!
    
    var textToSpeech: TextToSpeech!
    var languageTranslator: LanguageTranslator? = nil
    
    @IBOutlet weak var btnSave: UIButton!
    
    var isStreaming = false
    var stopStreaming: ((Void) -> Void)? = nil
    var delegate: ControlPanelDelegate?
    
    @IBOutlet weak var actionButton: ActionButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSessionAndRecorder()
        
        initTextToSpeech()
        initSpeechToText()
        initTranslator()
        
        let introduction = "Hi, I am mango. I could hear what people are saying then translate the speech into the language you preferred."
        self.textToSpeech(introduction)
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "mango", message: "save with a name?", preferredStyle: .alert)
        var nameField: UITextField? = nil
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            if let field = nameField {
                //save with the name provided or use the original
                if let name = field.text {
                    if !name.isEmpty {
                        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let filename = "\(name).m4a"
                        let fileURL = URL(fileURLWithPath: documents + "/" + filename)
                        do {
                            try FileManager.default.moveItem(at: self.audioFilePath, to: fileURL)
                            self.audioFilePath = fileURL
                            print(self.audioFilePath)
                        } catch {
                            print("ERROR moving sound file")
                        }
                    }
                }
                
                //TODO: API to upload the record audio file
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            print(#function)
        }
        
        alert.addTextField { (textField) in
            nameField = textField
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true) { }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH_mm_ss"
        let filename = "stt_\(formatter.string(from: Date())).m4a"
        audioFilePath = URL(fileURLWithPath: documents + "/" + filename)
        print(audioFilePath)
        
        audioService = AudioServiceImpl()
    }
    
    fileprivate func initSpeechToText() {
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
        
        
        speechToText = SpeechToText(username: user, password: password)

        speechToTextSession = SpeechToTextSession(username: user, password: password, model: "zh-CN_BroadbandModel")
        
//        speechToText.getModels { (models) in
//            print(models)
//        }
    }
    
    func textToSpeech(_ text: String) {
        let failure = { (error: Error) in print(error) }
        //TODO: voice as an configuration
        textToSpeech.synthesize(text, voice: SynthesisVoice.us_Allison.rawValue, failure: failure) { data in
            self.audioService.playWithData(data: data, renderWave: self.waveTimeView, completeHandle: { (data) in
                
            }, errorHandle: { (url, error) in
                failure(error)
            })
        }
    }
    
    fileprivate func startStopStreaming() {
        if (isStreaming) {
            stopStreaming?()
            isStreaming = false
            
            // stop recognizing microphone audio
            speechToTextSession.stopMicrophone()
            speechToTextSession.stopRequest()
            speechToTextSession.disconnect()
        }else {
            // set streaming
            isStreaming = true
            
            // define callbacks
            speechToTextSession.onConnect = { print("STT: connected") }
            speechToTextSession.onDisconnect = { print("STT: disconnected") }
            speechToTextSession.onError = { error in print(error) }
            //        speechToTextSession.onPowerData = { decibels in print(decibels) }
            //        speechToTextSession.onMicrophoneData = { data in print("received data") }
            
            speechToTextSession.onResults = { results in
                let bestTranscript = results.bestTranscript
                print("bestTranscript: \(bestTranscript)")
                self.delegate?.capturedSpeech(bestTranscript)
                
                guard let lastResult = results.results.last else { return }
                if lastResult.final == false { return }
                print("translating:\(bestTranscript)")
                
                //trigger translator only if last result's final value is true
                let failure = { (error: Error) in print(error) }
                self.languageTranslator?.translate(bestTranscript, withModelID: "zh-en-patent", failure: failure, success: { (translateResponse) in
                    if let trans = translateResponse.translations.first?.translation {
                        print("translated:" + trans)
                        DispatchQueue.main.async {
                            self.delegate?.translatedSpeech(trans)
                        }
                    }
                })
                
            }
            
            // define recognition request settings
            var settings = RecognitionSettings(contentType: .opus)
            settings.interimResults = true
            settings.continuous = true
            
            speechToTextSession.connect()
            speechToTextSession.startRequest(settings: settings)
            speechToTextSession.startMicrophone()
        }
        
    }
    
    fileprivate func startStopRecording() {
        if audioService.isRecording {
            actionButton.stopAction(false)
            audioService.stop()
            print("recorder stopped")
        } else {
            self.btnSave.isHidden = true
            actionButton.startAction()
            audioService.record(fileURL: audioFilePath, renderWave: waveTimeView, completeHandle: { (url) in
                print("completeHandle: \(url)")
                self.btnSave.isHidden = false
            }, errorHandle: { (url, error) in
                print("errorHandle: \(url) \(error)")
            })
        }
        
    }
    
    fileprivate func failure(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { action in }
        alert.addAction(ok)
        present(alert, animated: true) { }
    }
    
    
    fileprivate func titleCase(_ s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercased()
        return first + String(s.characters.dropFirst())
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

//TTS
extension ControlPanel {
    
    fileprivate func initTextToSpeech() {
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
        
        textToSpeech = TextToSpeech(username: user, password: password)
        
//        textToSpeech.getVoices { (voices) in
//            print(voices)
//        }
    }

}

extension ControlPanel {
    
    fileprivate func initTranslator() {
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
        

        languageTranslator = LanguageTranslator(username: user, password: password)
        
//        languageTranslator!.getModels { (models) in
//            print(models)
//        }
        
    }
}
