//
//  AudioService.swift
//  Mango
//
//  Created by Wesley Sui on 05/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import AVFoundation

typealias AudioServiceCompletionBlockWithData = (_ data : Data) -> ()
typealias AudioServiceCompletionBlock = (_ url:URL) -> ()
typealias AudioServiceErrorBlock = (_ url:URL, _ error:Error) -> ()

protocol IAudioService {
    func record(fileURL:URL, renderWave waveView: AudioWaveView?, completeHandle:AudioServiceCompletionBlock?, errorHandle:AudioServiceErrorBlock?)
    func playWithData(data:Data, renderWave waveView: AudioWaveView?, completeHandle:AudioServiceCompletionBlockWithData?, errorHandle:AudioServiceErrorBlock?)
    func pause()
    func stop()
    var isPlaying: Bool {get}
    var isRecording: Bool {get}
}

class AudioServiceImpl:NSObject, IAudioService, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var player: AVAudioPlayer!
    var recorder: AVAudioRecorder!
    
    var meterTimer: Timer?
    
    var completeHandleWithData: AudioServiceCompletionBlockWithData?
    var completeHandle: AudioServiceCompletionBlock?
    var errorHandle: AudioServiceErrorBlock?
    
    //
    weak var meterView: AudioWaveView?
    var waveData: [Float] = [Float](repeating: 0.0, count: 1000)
    var noise: Float = 0.0
    var noiseCount = 0
    let numberOfTrialToDetermineNoise = 20
    
    override init() {
        super.init()
        setSessionPlayAndRecord()
    }
    
    private func setSessionPlayAndRecord() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        } catch {
            print("could not set session category")
            return
        }
        do {
            try session.setActive(true)
        } catch {
            print("could not make session inactive")
        }
    }
    
    private func setupRecorder(fileURL:URL) -> Error? {

        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("duplicated sournd file at: \(fileURL)")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("ERROR deleting dulpicate sound file")
            }
        }
        
        let recordSettings = [AVSampleRateKey : NSNumber(value: Float(44100.0)),
                              AVFormatIDKey : NSNumber(value: Int32(kAudioFormatAppleLossless)),
                              AVNumberOfChannelsKey : NSNumber(value: 2),
                              AVEncoderBitRateKey : NSNumber(value: 320000),
                              AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.max.rawValue))]
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            try recorder = AVAudioRecorder(url: fileURL, settings: recordSettings)
            recorder.prepareToRecord()
            recorder.delegate = self
            recorder.isMeteringEnabled = true
        } catch {
            print("Error in start recording")
        }
        
        return nil
    }
    
    var isRecording: Bool {
        get {
            return recorder != nil && recorder.isRecording
        }
    }
    
    var isPlaying: Bool {
        get {
            return player != nil && player.isPlaying
        }
    }
    
    func record(fileURL: URL, renderWave waveView: AudioWaveView?, completeHandle: AudioServiceCompletionBlock?, errorHandle: AudioServiceErrorBlock?) {
        if recorder != nil && recorder.isRecording == false {
            //resume recording
            recorder.record()
            return
        }
        
        stop()
        
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    if self.recorder == nil {
                        let error = self.setupRecorder(fileURL: fileURL)
                        if error != nil {
                            errorHandle?(fileURL, error!)
                            return
                        }
                    }
                    
                    print("recording")
                    self.meterView = waveView
                    self.completeHandle = completeHandle
                    self.errorHandle = errorHandle
                    
                    self.recorder.record()
                    
                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                                             target:self,
                                                                             selector:#selector(AudioServiceImpl.updateAudioMeter(timer:)),
                                                                             userInfo:nil,
                                                                             repeats:true)
                } else {
                    print("Permission to record not granted")
                    errorHandle?(fileURL, NSError(domain: "AudioServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Permission to record granted failed"]))
                }
            })
        }
    }
    
    func playWithData(data: Data, renderWave waveView: AudioWaveView?, completeHandle: AudioServiceCompletionBlockWithData?, errorHandle: AudioServiceErrorBlock?) {
        if let _ = player  {
            if let _ = player.url {
                stop()
            }
        }
        
        if player != nil && player.isPlaying == false {
            //resume playing
            player.play()
            return
        }
        
        stop()
        
        do {
            self.player = try AVAudioPlayer(data: data, fileTypeHint: "m4a")
        } catch {
            print("ERROR")
            return
        }
        
        self.completeHandleWithData = completeHandle
        self.errorHandle = errorHandle
        
        if let meter = waveView {
            self.meterView = meter
            player.isMeteringEnabled = true
        }
        
        player.delegate = self
        player.prepareToPlay()
        player.volume = 1.0
        player.play()
        
        let selector = #selector(AudioServiceImpl.updateAudioMeter(timer:))
        self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: selector, userInfo: nil, repeats: true)
    }
    
    func stop() {
        var isActive = false
        
        if recorder != nil {
            isActive = true
            recorder.stop()
            self.completeHandle?(recorder.url)
            recorder = nil
        }
        
        if player != nil {
            isActive = true
            player.stop()
            if (player.url != nil) {
                self.completeHandle?(player.url!)
            } else {
                self.completeHandleWithData?(player.data!)
            }
            player = nil
        }
        
        if !isActive {
            return
        }
        
        //clean
        completeHandle = nil
        errorHandle = nil
        meterTimer?.invalidate()
        meterTimer = nil
        waveData.removeAll(keepingCapacity: true)
        
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        do {
            try session.setActive(true)
        } catch {
            print("could not make session inactive")
        }
    }
    
    func pause() {
        if recorder != nil && recorder.isRecording {
            print("pause while recording")
            recorder.pause()
            return
        }
        if player != nil && player.isPlaying {
            print("pause while playing")
            player.pause()
            return
        }
    }
    
    func updateAudioMeter(timer: Timer) {
        var timelabel = ""
        var apc0:Float = 0.0
        var peak0 : Float = 0.0
        //Some warning(variable was written, but never read?) was coming for which written below code
        if peak0 == 0.0
        {
            peak0 = 0.0
        }
        let dFormat = "%02d"
        if let recorder = self.recorder {
            if recorder.isRecording {
                let min:Int = Int(recorder.currentTime / 60)
                let sec:Int = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                timelabel = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
                recorder.updateMeters()
                
                apc0 = recorder.averagePower(forChannel: 0)
                peak0 = recorder.peakPower(forChannel: 0)
            }
        }else if let player = self.player {
            if player.isPlaying {
                let min:Int = Int(player.currentTime / 60)
                let sec:Int = Int(player.currentTime.truncatingRemainder(dividingBy: 60))
                timelabel = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
                player.updateMeters()
                apc0 = player.averagePower(forChannel: 0)
                peak0 = player.peakPower(forChannel: 0)
            }
        }else {
            return
        }
      
        if (fabs(fabs(apc0) - fabs(noise)) > 10.0) {
            if noiseCount < numberOfTrialToDetermineNoise {
                noise = apc0
                noiseCount = 0
            } else {
                apc0 *= 2
            }
        } else {
            if noiseCount >= numberOfTrialToDetermineNoise {
                apc0 = fabs(apc0 - noise) - 160
            } else {
                noiseCount = noiseCount + 1
            }
        }
        
        if waveData.count >= waveData.capacity {
            waveData.remove(at: 0)
        }
        waveData.append(Float(apc0 + 160.0))
        meterView?.update(time: timelabel, withWaveData: waveData)
    }
    
    //MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stop()
        } else {
            player.stop()
            errorHandle?(player.url!, NSError(domain: "AudioServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Audio Play Finish Failed"]))
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        player.stop()
        errorHandle?(player.url!, error! as NSError)
    }
    
    // Mark:- AVAudioRecordDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
//            stop()
        } else {
            recorder.stop()
            errorHandle?(recorder.url, NSError(domain: "AudioServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Audio Record Finish Failed"]))
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recorder.stop()
        errorHandle?(recorder.url, error!)
    }
}

