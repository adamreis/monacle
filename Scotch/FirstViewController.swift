//
//  FirstViewController.swift
//  Scotch
//
//  Created by Brian Donghee Shin on 1/17/15.
//  Copyright (c) 2015 Adam Reis. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import AVFoundation

class FirstViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    private var firstVideoURL: NSURL?
    private var secondVideoURL: NSURL?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        firstVideoURL = nil
        secondVideoURL = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        if firstVideoURL != nil && secondVideoURL != nil {
            println("Have both videos!")
            println(firstVideoURL)
            println(secondVideoURL)
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
