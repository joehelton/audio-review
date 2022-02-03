//
//  ViewController.swift
//  Recorder
//
//  Created by Joe Helton on 1/31/22.
//

import Foundation
import AVFoundation
import UIKit

class ViewController: UIViewController {

    let waveformView = EGAAudioWaveformView()
    let playheadImageView = UIImageView()
    let scrollView = UIScrollView()
    let instructionsLabel = UILabel()
    let recordButton = UIButton(type: .custom)
    
    var audioRecorder: EGAAudioRecorder?
    var isRecording = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        configure()
        layout()
        initializeAudio()
    }
    
    @objc func recordButtonPressed() {
        
        if (isRecording) {
            stopRecording()
        } else {
            startRecording()
        }
        isRecording = !isRecording
    }
    
    @objc func pinchGestureRecognized(pinchGesture: UIPinchGestureRecognizer) {
        
        var scale = waveformView.xScale + (pinchGesture.scale - 1.0)
        
        if scale > 5 {
            scale = 5
        }
        if scale < 0.1 {
            scale = 0.1
        }
        
        waveformView.xScale = scale
        pinchGesture.scale = 1.0
    }
}

// MARK: - View Configuration
extension ViewController {
    
    private func configure() {
        
        waveformView.backgroundColor = UIColor.appControlColor()
        waveformView.baselineColor = UIColor.appControlDisabledColor()
        waveformView.beforePlayheadWaveformGradientColor1 = UIColor.appControlColorDark()
        waveformView.beforePlayheadWaveformGradientColor2 = UIColor.appControlColorDark()
        waveformView.afterPlayheadWaveformGradientColor1 = UIColor.appControlDisabledColor()
        waveformView.afterPlayheadWaveformGradientColor2 = UIColor.appControlDisabledColor()
        waveformView.isInverted = false
        waveformView.audioDuration = 0
        waveformView.audioPositionAtPlayhead = 0
        waveformView.yScale = 1.8
        waveformView.xScale = 3.0
        waveformView.playheadRelativeXPosition = 0.5
        
        playheadImageView.image = UIImage(named: "playhead_overwrite")
        
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognized))
        scrollView.addGestureRecognizer(pinchGesture)
        
        instructionsLabel.text = "Swipe to scroll through audio waveform. Pinch to zoom."
        instructionsLabel.numberOfLines = 2
        instructionsLabel.textAlignment = .center
        instructionsLabel.textColor = UIColor.appControlColorLight()
        instructionsLabel.isHidden = true
        
        recordButton.setTitle("RECORD", for: .normal)
        recordButton.backgroundColor = UIColor.appRecordingTintColor()
        recordButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
    }
}

// MARK: - View Layout
extension ViewController {

    private func layout() {
        
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformView)
        NSLayoutConstraint.activate([
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveformView.topAnchor.constraint(equalTo: view.topAnchor),
            waveformView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0)
        ])
        
        playheadImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playheadImageView)
        NSLayoutConstraint.activate([
            playheadImageView.centerXAnchor.constraint(equalTo: waveformView.centerXAnchor),
            playheadImageView.centerYAnchor.constraint(equalTo: waveformView.centerYAnchor),
        ])
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0)
        ])
        
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsLabel)
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0),
            instructionsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0)
        ])
        
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.heightAnchor.constraint(equalToConstant: 60.0),
            recordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: waveformView.bounds.width)
    }
}

// MARK: - Audio Functionality
extension ViewController {
    
    func initializeAudio() {
        
        //configure audio session with basic debug error handling for now
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { (granted: Bool) -> Void in
            
            if granted {
                var error: NSError?
                do {
                    try session.setCategory(AVAudioSession.Category.playAndRecord)
                } catch let error1 as NSError {
                    error = error1
                } catch {
                    fatalError()
                }
                if let e = error {
                    print("Audio Initialization Failed")
                    print(e.localizedDescription)
                }
                error = nil
                do {
                    try session.setActive(true)
                } catch let error1 as NSError {
                    error = error1
                } catch {
                    fatalError()
                }
                if let e = error {
                    print("Audio Initialization Failed")
                    print(e.localizedDescription)
                }
                do {
                    try session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                } catch _ {
                }
            } else {
                    print("Audio Initialization Failed")
                    print("Recording permission denied.")
            }
        }
        
        //define a file url for our recording audio file
        var url: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url.appendingPathComponent("recording.\(EGAAudioFileExtension)")
        
        //initialize the audio recorder with the file url
        if let recorder = EGAAudioRecorder(url: url) {
            self.audioRecorder = recorder
            recorder.delegate = self
            recorder.prepareToRecord()
        }
    }
    
    func startRecording() {
        
        if let recorder = self.audioRecorder {
            recorder.record()
        }
        recordButton.setTitle("STOP", for: .normal)
        instructionsLabel.isHidden = true
        scrollView.isScrollEnabled = false
    }
    
    func stopRecording() {
        
        if let recorder = self.audioRecorder {
            recorder.stop()
        }
        recordButton.setTitle("RECORD", for: .normal)
        instructionsLabel.isHidden = false
        scrollView.isScrollEnabled = true
    }
}

// MARK: - Audio Recorder Delegate
extension ViewController: EGAAudioRecorderDelegate {
    
    func audioRecorderErrorOccurred(_ recorder: EGAAudioRecorder!, error: Error!) {
        
        print(error.localizedDescription)
    }
    
    func audioRecorder(_ recorder: EGAAudioRecorder!, didRecordAudioAtPeakAudioLevel level: Float, withUpdatedDuration duration: TimeInterval) {
        
        //update waveform
        var levelVar = level
        waveformView.audioWaveformData.append(&levelVar, length: MemoryLayout<Float>.size)
        waveformView.audioDuration = duration
        waveformView.audioPositionAtPlayhead = duration
        
        //update scrollview
        let offset = (waveformView.audioDuration > 0) ? waveformView.audioPositionAtPlayhead / waveformView.audioDuration : 0
        scrollView.contentSize = waveformView.waveformSize()
        scrollView.contentOffset = CGPoint(x: scrollView.contentSize.width * CGFloat(offset), y: 0)
    }
}

// MARK: - Scroll View Delegate
extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.x / scrollView.contentSize.width
        waveformView.audioPositionAtPlayhead = waveformView.audioDuration * TimeInterval(offset)
    }
}
