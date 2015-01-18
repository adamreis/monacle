//
//  AppDelegate.swift
//  Scotch
//
//  Created by Brian Donghee Shin on 1/17/15.
//  Copyright (c) 2015 Brian Donghee Shin. All rights reserved.
//

import UIKit
//import FirstViewController
//import SecondViewController
//import ThirdViewController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let tabBarController = UITabBarController()
        
        let vc1 = FirstViewController(nibName: "FirstViewController", bundle: nil)
        let vc2 = SecondViewController(nibName: "SecondViewController", bundle: nil)
        let vc3 = ThirdViewController(nibName: "ThirdViewController", bundle: nil)
        
        vc1.tabBarItem = UITabBarItem(title: "First", image: nil, tag: 1)
        vc2.tabBarItem = UITabBarItem(title: "Second", image: nil, tag: 2)
        vc3.tabBarItem = UITabBarItem(title: "Third", image: nil, tag: 3)
        
        tabBarController.viewControllers = [vc1, vc2, vc3]
        window?.rootViewController = tabBarController
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

