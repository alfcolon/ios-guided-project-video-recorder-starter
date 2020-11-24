//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import AVFoundation
import UIKit

class CameraViewController: UIViewController {

    //MARK: - IBOutlets
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    //MARK: - Properties
    
    var captureSession = AVCaptureSession()
    var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer?
    private var playerView: VideoPlayerView!
    
    //MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Resize camera preview to fill the entire screen
        self.cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        self.setupCaptureSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.captureSession.startRunning()
    }
    
    //MARK: - Methods
    
    func setupCaptureSession() {
          
        //Let the capture session know we are going ot be changing its settings (inputs, outputs)
        self.captureSession.beginConfiguration()
        
        //Camera
        
        let camera = self.bestCamera()
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            self.captureSession.canAddInput(cameraInput) else {
                // FUTURE: Display the error that gets thrown so you understand why it doesn't work
                fatalError("Cannot create camera input. Do something better than crashing here.")
        }
        
        self.captureSession.addInput(cameraInput)
        
        //Microphone
        
        let microphone = self.bestAudio()
        
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone),
            self.captureSession.canAddInput(audioInput) else {
                fatalError("Can't create and add input for microphone")
        }
        
        self.captureSession.addInput(audioInput)
        
        // Quality Level
        
        if self.captureSession.canSetSessionPreset(.hd1920x1080) {
            self.captureSession.sessionPreset = .hd1920x1080
        }
        
        // Output(s)
        
        guard self.captureSession.canAddOutput(self.fileOutput) else { fatalError("Cannot add the movie recording output") }
        
        self.captureSession.addOutput(self.fileOutput)
        
        // Begin to use the settings that we've configured above
        self.captureSession.commitConfiguration()
        
        // Give the camera view the session so it can show the camera preview to the user
        cameraView.session = self.captureSession
    }
    
    private func updateViews() {
        self.recordButton.isSelected = self.fileOutput.isRecording
    }
    
    private func playmovie(at url: URL) {
        let player = AVPlayer(url: url)
        
        if playerView == nil {
            // Set up te player view the first time
            
            let playerView = VideoPlayerView()
            playerView.player = player
            
            // Customize the frame
            
            var frame = view.bounds
            frame.size.height /= 4
            frame.size.width /= 4
            
            frame.origin.y = self.view.directionalLayoutMargins.top
            
            playerView.frame = frame
            
            self.view.addSubview(playerView)
        }
        
        player.play()
        // Make sure the player sticks arond as long as needed
        self.player = player
    }
    
    private func bestCamera() -> AVCaptureDevice {
        // Chose the ideal camera available for the device
        // FUTURE: We could cadd a button to let the user choose front/back camera
        
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        } else if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideAngleCamera
        }
        
        fatalError("No camera available. Are you on a simulator?")
    }
    
    private func bestAudio() -> AVCaptureDevice {
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            return audioDevice
        }
        fatalError("No audio capture device present")
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        self.toggleRecording()
	}
	
    private func toggleRecording() {
        
        if self.fileOutput.isRecording {
            // Stop the recording
            self.fileOutput.stopRecording()
            self.updateViews()
        } else {
            self.fileOutput.startRecording(to: self.newRecordingURL(), recordingDelegate: self)
            self.updateViews()
        }
    }
    
    
    
	// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording at \(fileURL)")
        self.updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.updateViews()
        
        if let error = error {
            NSLog("Error saving movie: \(error)")
        }
        
        DispatchQueue.main.async {
            self.playmovie(at: outputFileURL)
        }
    }
}
