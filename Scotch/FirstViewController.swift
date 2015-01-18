//
//  FirstViewController.swift
//  Scotch
//
//  Created by Adam Reis on 1/17/15.
//  Copyright (c) 2015 Adam Reis. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import AVFoundation
import AssetsLibrary

class FirstViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private var firstVideoURL: NSURL?
    private var secondVideoURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        if firstVideoURL != nil && secondVideoURL != nil {
            println("Have both videos!")
            println(firstVideoURL)
            println(secondVideoURL)
            self.stitchVideos()
            //            self.playVideo()
        }
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            
            var imag = UIImagePickerController()
            imag.delegate = self
            imag.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imag.mediaTypes = [kUTTypeMovie]
            imag.allowsEditing = false
            
            self.presentViewController(imag, animated: true, completion: nil)
        }
    }
    
    func stitchVideos(){
        // Based on https://abdulazeem.wordpress.com/2012/04/02/
        
        // Load movies
        let firstAsset: AVURLAsset = AVURLAsset(URL: firstVideoURL, options: nil)
        let secondAsset: AVURLAsset = AVURLAsset(URL: secondVideoURL, options: nil)
        
        var myError: NSError?
        
        var duration: CMTime = secondAsset.duration
        if CMTimeCompare(firstAsset.duration, secondAsset.duration) < 0 {
            duration = firstAsset.duration
        }
        let timeRange = CMTimeRangeMake(kCMTimeZero, duration)
        
        // Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
        let mixComposition: AVMutableComposition = AVMutableComposition()
        
        // Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
        let firstTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        // Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
        firstTrack.insertTimeRange(timeRange, ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack, atTime: kCMTimeZero, error: &myError)
        
        // Now we repeat the same process for the 2nd track as we did above for the first track.Note that the new track also starts at kCMTimeZero meaning both tracks will play simultaneously.
        let secondTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        secondTrack.insertTimeRange(timeRange, ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack, atTime: kCMTimeZero, error: &myError)
        
        // Now create audio track from first asset
        let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        audioTrack.insertTimeRange(timeRange, ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeAudio)[0] as AVAssetTrack, atTime: kCMTimeZero, error: &myError)
        
        // See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
        let MainInstruction = AVMutableVideoCompositionInstruction()
        MainInstruction.timeRange = timeRange
        
        // We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
        let FirstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        let FirstTranslation = firstAsset.preferredTransform
        FirstLayerInstruction.setTransform(FirstTranslation, atTime: kCMTimeZero)
        
        // Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
        let SecondLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
        let Move = CGAffineTransformMakeTranslation(1280, 0)
        SecondLayerInstruction.setTransform(Move, atTime: kCMTimeZero)
        
        // Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
        MainInstruction.layerInstructions = [FirstLayerInstruction, SecondLayerInstruction]
        
        // Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
        let MainCompositionInst = AVMutableVideoComposition()
        MainCompositionInst.instructions = [MainInstruction]
        MainCompositionInst.frameDuration = CMTimeMake(1, 30)
        MainCompositionInst.renderSize = CGSizeMake(2560, 720)
        
        // Play it
        let newPlayerItem = AVPlayerItem(asset: mixComposition)
        newPlayerItem.videoComposition = MainCompositionInst
        let mPlayer = AVPlayer(playerItem: newPlayerItem)
        let mPlaybackView = AVPlayerLayer(player:mPlayer)
        mPlaybackView.frame = self.view.frame
        mPlayer.play()
        
        let containerView = UIView(frame: self.view.frame)
        containerView.layer.addSublayer(mPlaybackView)
        self.view.addSubview(containerView)
        
        
        // Save it to camera roll
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
        if ((dirs) != nil) {
            let dir = dirs![0]; //documents directory
            let path = dir.stringByAppendingPathComponent("testVideo.mov");
            
            // Delete whatever was there originally
            let fileManager = NSFileManager.defaultManager()
            fileManager.removeItemAtPath(path, error: nil)
            
            // Asynchronously export the composition to a video file and save this file to the camera roll once export completes.
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter.outputURL = NSURL(fileURLWithPath: path)
            exporter.videoComposition = MainCompositionInst
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = false
            
            exporter.exportAsynchronouslyWithCompletionHandler({
                dispatch_async(dispatch_get_main_queue(), {
                    if exporter.status == .Completed {
                        let assetsLibrary = ALAssetsLibrary()
                        
                        if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(exporter.outputURL) {
                            assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(exporter.outputURL, completionBlock: {(NSURL, NSError) -> Void in
                                fileManager.removeItemAtPath(path, error: nil)
                                println("Saved to camera roll!")
                                return
                            })
                        }
                    }
                })
            })
        }
    }
    
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        println("I've got some media")
        let movieURL = info[UIImagePickerControllerMediaURL] as NSURL
        if firstVideoURL == nil {
            firstVideoURL = movieURL
        } else if secondVideoURL == nil {
            secondVideoURL = movieURL
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
}
