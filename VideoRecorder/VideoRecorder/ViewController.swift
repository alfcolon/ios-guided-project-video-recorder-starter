//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// TODO: get permission
		
        self.requestPermissionAndShowCamera()
        
    }
    
    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            self.showCamera()
        case .denied:
            // take the user to the settings app (or show a custom onboarding screen explaining why we need camera access
            fatalError("Camera permission denied")
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                guard granted else { fatalError("Camera permission denied") }
            }
            
            DispatchQueue.main.async {
                self.showCamera()
            }
        case .restricted:
            // Parental Controls (inform the user they do not have access. Maybe ask a parent?)
            fatalError("Camera permission denied")
        @unknown default:
            fatalError("Unexpected enum value that isn't being handled")
        }
        
    }
    
    private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}
