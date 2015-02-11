//
//  VideoProcessing.swift
//  Scotch
//
//  Created by Adam Reis on 1/18/15.
//  Copyright (c) 2015 Brian Donghee Shin. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

var exporter: AVAssetExportSession?
var stillGoing = true

func stitchVideos(url1: NSURL, url2: NSURL, progressHUD: MBProgressHUD, completion: (result: String) -> Void){
    // Based on https://abdulazeem.wordpress.com/2012/04/02/

    progressHUD.progress = 0.0
    
    // Load movies
    let firstAsset: AVURLAsset = AVURLAsset(URL: url1, options: nil)
    let secondAsset: AVURLAsset = AVURLAsset(URL: url2, options: nil)
    
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
    let Move = CGAffineTransformMakeTranslation(1080, 0)
    SecondLayerInstruction.setTransform(Move, atTime: kCMTimeZero)
    
    // Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [FirstLayerInstruction, SecondLayerInstruction]
    
    // Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    let MainCompositionInst = AVMutableVideoComposition()
    MainCompositionInst.instructions = [MainInstruction]
    MainCompositionInst.frameDuration = CMTimeMake(1, 30)
    MainCompositionInst.renderSize = CGSizeMake(2160, 810)
    
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            while(abs(exporter.progress - 1.0)>0.05 && stillGoing){
                println("loading... : \(exporter.progress)");
                progressHUD.progress = exporter.progress
                usleep(200000);
                }
            return
            });
        
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                if exporter.status == .Completed {
                    let assetsLibrary = ALAssetsLibrary()
                    
                    if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(exporter.outputURL) {
                        assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(exporter.outputURL, completionBlock: {(NSURL, NSError) -> Void in
                            fileManager.removeItemAtPath(path, error: nil)
                            println("Saved to camera roll!")
                            
//                            dispatch_async(dispatch_get_main_queue(), {
//                                    progressHUD.hide(true)
//                                })
                            stillGoing = false
                            completion(result: "Success")
                            return
                        })
                    }
                }
            })
        })
    }
}