//
//  ThirdViewController.swift
//  Scotch
//
//  Created by Adam Reis on 1/17/15.
//  Copyright (c) 2015 Adam Reis. All rights reserved.
//

import UIKit
import AVFoundation

class ThirdViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    let videoUrl : NSURL?
    
    // If we find a device we'll store it here for later use
    var videoCaptureDevice : AVCaptureDevice?
    var audioCaptureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if device.hasMediaType(AVMediaTypeVideo) {
                // Finally check the position and confirm we've got the back camera
                if device.position == AVCaptureDevicePosition.Back {
                    videoCaptureDevice = device as? AVCaptureDevice
                }
            } else if device.hasMediaType(AVMediaTypeAudio) && audioCaptureDevice == nil {
                audioCaptureDevice = device as? AVCaptureDevice
            }
        }
        if videoCaptureDevice != nil && audioCaptureDevice != nil {
            println("Capture devices found")
            beginSession()
        }
        
    }
    
    func startPreview() {
        var err : NSError?
        captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice, error: &err))
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        captureSession.addInput(AVCaptureDeviceInput(device: audioCaptureDevice, error: &err))
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
    }
    
    func startRecording() {
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
        if ((dirs) != nil) {
            let dir = dirs![0]; //documents directory
            let path = dir.stringByAppendingPathComponent("testVideo.mov");
            
            // Delete whatever was there originally
            let fileManager = NSFileManager.defaultManager()
            fileManager.removeItemAtPath(path, error: nil)
            
            //            movieOutput = AVCaptureMovieFileOutput()
        }
    }
    
    func beginSession() {
        startPreview()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        self.view.backgroundColor = UIColor.yellowColor()
//        previewLayer?.frame = self.view.layer.frame
//        previewLayer?.frame = CGRectMake(0,0,300,300)
        previewLayer?.frame = CGRectMake(0, 0, UIScreen.mainScreen().applicationFrame.size.width, UIScreen.mainScreen().applicationFrame.size.width)
        captureSession.startRunning()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 5))
        dispatch_after(delayTime, dispatch_get_main_queue()){
            
        }
    }
    
    
}
