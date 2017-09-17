//
//  InterfaceController.swift
//  AirPodTestwatchOS WatchKit Extension
//
//  Created by Jacopo Mangiavacchi on 9/17/17.
//  Copyright © 2017 JacopoMangia. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation

class InterfaceController: WKInterfaceController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet var recordingButton: WKInterfaceButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    enum RecPlayStatus {
        case Recording
        case Playback
    }
    
    var status = RecPlayStatus.Recording
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        super.willActivate()
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.allowBluetoothA2DP])
            try recordingSession.setActive(true)
            
//            let availableInputs = recordingSession.availableInputs
//            for input in availableInputs! {
//                print(input)
//            }
//            let input = availableInputs!.count > 0 ? availableInputs![1] : availableInputs![0]
//            try recordingSession.setPreferredInput(input)
            
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.recordingButton.setEnabled(true)
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch let error {
            print(error)
        }
    }

    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    @IBAction func onRecording() {
        switch status {
        case .Recording:
            if audioRecorder == nil {
                startRecording()
            } else {
                finishRecording(success: true)
            }
        case .Playback:
            playback()
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try recordingSession.overrideOutputAudioPort(AVAudioSessionPortOverride.none)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordingButton.setTitle("Stop Rec")
            recordingButton.setBackgroundColor(.orange)
        } catch {
            finishRecording(success: false)
        }
    }
    
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            status = RecPlayStatus.Playback
            recordingButton.setTitle("Playback")
            recordingButton.setBackgroundColor(.blue)
        } else {
            status = RecPlayStatus.Recording
            recordingButton.setTitle("(KO) Start New Rec")
            recordingButton.setBackgroundColor(.red)
            // recording failed :(
        }
    }
    
    
    func playback() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            //try recordingSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            
            try audioPlayer = AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch let error {
            print(error)
        }
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        status = RecPlayStatus.Recording
        recordingButton.setTitle("Start New Rec")
        recordingButton.setBackgroundColor(.red)
    }
    
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print(e)
        }
    }
}
