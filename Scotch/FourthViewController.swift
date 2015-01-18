//
//  FourthViewController.swift
//  Scotch
//
//  Created by Adam Reis on 1/17/15.
//  Copyright (c) 2015 Brian Donghee Shin. All rights reserved.
//

import UIKit
import AssetsLibrary

class FourthViewController: UIViewController, PBJVisionDelegate, UIAlertViewDelegate {

    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    var LRLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let previewView = UIView(frame: CGRectZero)
        previewView.backgroundColor = UIColor.blackColor()
        var previewFrame = self.view.frame
//        previewFrame.origin.y = previewFrame.origin.y + 50
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
        
//        LRLabel = UILabel(frame: self.view.frame)
//        LRLabel!.center = CGPointMake(140, 426)
//        LRLabel!.textAlignment = .Center
//        LRLabel!.font = UIFont.systemFontOfSize(250)
//        LRLabel!.textColor = UIColor.whiteColor()
//        LRLabel!.text = "L"
//        self.view.addSubview(LRLabel!)
        
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark))
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.frame = view.frame
        vibrancyView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(vibrancyView)
        
        
        LRLabel = UILabel(frame: vibrancyView.frame)
        LRLabel!.center = CGPointMake(140, 426)
        LRLabel!.textAlignment = .Center
        LRLabel!.font = UIFont.systemFontOfSize(250)
        LRLabel!.textColor = UIColor.whiteColor()
        LRLabel!.text = "L"
        vibrancyView.contentView.addSubview(LRLabel!)
        
        PBJVision.sharedInstance().startPreview()
        println("viewDidLoad finished")
    }

    override func viewDidAppear(animated: Bool) {
        println("viewDidAppear")
        
    }
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .Began:
            PBJVision.sharedInstance().startVideoCapture()
        case .Changed:
            break
        default:
            PBJVision.sharedInstance().endVideoCapture()
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
                let alert = UIAlertView(title: "Video Saved!", message: "Saved to camera roll.", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "OK")
                alert.show()
                return
            })
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
