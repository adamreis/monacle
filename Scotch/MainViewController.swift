//
//  MainViewController.swift
//  Scotch
//
//  Created by Adam Reis on 1/18/15.
//  Copyright (c) 2015 Brian Donghee Shin. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AssetsLibrary

enum Side : Int {
    case Left
    case Right
}

enum Role : Int {
    case Master
    case Slave
}

class MainViewController: UIViewController, PeerConnectorDelegate, PBJVisionDelegate, UIAlertViewDelegate {

    let connector = PeerConnector()
    var ourRole: Role?
    var ourSide: Side?
    var LRLabel: UILabel?
    var ourVidURL: NSURL?
    
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connector.delegate = self
        connector.startAdvertisingToPeers()
        connector.startSearchForPeers()
        
        let previewView = UIView(frame: CGRectZero)
        previewView.backgroundColor = UIColor.blackColor()
        var previewFrame = self.view.frame
        previewView.frame = previewFrame
        let previewLayer = PBJVision.sharedInstance().previewLayer
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewView.layer.addSublayer(previewLayer)
        self.view.addSubview(previewView)
        
        let vision = PBJVision.sharedInstance()
        vision.delegate = self
        vision.cameraMode = .Video
        vision.cameraOrientation = .Portrait
        vision.focusMode = .ContinuousAutoFocus
        vision.outputFormat = PBJOutputFormat.Standard
        vision.captureSessionPreset = AVCaptureSessionPresetHigh
        
//        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark))
//        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
//        vibrancyView.frame = view.frame
//        vibrancyView.setTranslatesAutoresizingMaskIntoConstraints(false)
//        self.view.addSubview(vibrancyView)
        
        
//        LRLabel = UILabel(frame: vibrancyView.frame)
        LRLabel = UILabel(frame: view.frame)
        LRLabel!.center = CGPointMake(140, 426)
        LRLabel!.textAlignment = .Center
        LRLabel!.font = UIFont.systemFontOfSize(250)
        LRLabel!.textColor = UIColor.whiteColor()
        LRLabel!.text = ""
        LRLabel!.hidden = true
        previewView.addSubview(LRLabel!)
        
        view.backgroundColor = UIColor.orangeColor()
    }

    override func viewDidAppear(animated: Bool) {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    }
    
    
    @IBAction func longPressRecognized(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .Began:
            ourRole = .Master
            connector.sendSignal(connector.getOneClientID(), messageType: .StartRecording)
            PBJVision.sharedInstance().startVideoCapture()
            LRLabel!.hidden = true
        case .Changed:
            break
        default:
            connector.sendSignal(connector.getOneClientID(), messageType: .StopRecording)
            PBJVision.sharedInstance().endVideoCapture()
            LRLabel!.hidden = false
        }
    }
    
    func vision(vision: PBJVision!, capturedVideo videoDict: [NSObject : AnyObject]!, error: NSError!) {
        if (error != nil) {
            print("encountered an error in video capture")
            println(error)
            return
        }
        
        let currentVideo = videoDict
        let videoPath = currentVideo[PBJVisionVideoPathKey] as NSString
        let videoURL = NSURL(fileURLWithPath: videoPath)
        
        let assetsLibrary = ALAssetsLibrary()
        
        if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL) {
            assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(videoURL, completionBlock: {(NSURL, NSError) -> Void in
                if self.ourRole == .Slave {
                    let alert = UIAlertView(title: "Video Sent!", message: "Sent video and saved to camera roll.", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "OK")
                    alert.show()
                }
                return
            })
        }
        
        if ourRole == .Slave {
            connector.sendVideo(videoURL!)
        }
        ourVidURL = videoURL
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: -
    // MARK: PeerConnectorDelegate
    
    func connector(connector: PeerConnector, didConnectToPeer peerID: MCPeerID) {
        if connector.localPeerID.displayName < peerID.displayName {
            ourSide = .Left
            LRLabel!.text = "L"
        } else {
            ourSide = .Right
            LRLabel!.text = "R"
        }
        println("ourSide: \(ourSide?.rawValue)")
        LRLabel!.hidden = false
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        PBJVision.sharedInstance().startPreview()
    }
    
    func connector(connector: PeerConnector, didFinishVideoSend videoURL: NSURL) {
        
    }
    
    func connector(connector: PeerConnector, didFinishVieoRecieve videoURL: NSURL) {
        var leftURL, rightURL: NSURL?
        switch ourSide! {
        case .Left:
            leftURL = ourVidURL
            rightURL = videoURL
        default:
            leftURL = videoURL
            rightURL = ourVidURL
        }
        
//        stitchVideos(leftURL!, rightURL!)
        stitchVideos(leftURL!, rightURL!) { (result) -> Void in
            let alert = UIAlertView(title: "Video Saved!", message: "Saved 3D video to camera roll.", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "OK")
            alert.show()
            return
        }
    }
    
    func receivedSignal(signalType: MessageTypes) {
        switch signalType {
        case .StartRecording:
            PBJVision.sharedInstance().startVideoCapture()
            LRLabel!.hidden = true
            println("start recording")
            ourRole = .Slave
        case .StopRecording:
            PBJVision.sharedInstance().endVideoCapture()
            LRLabel!.hidden = false
            println("stop recording")
        }
        
    }
}
