//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window?.tintColor = UIColor.orangeColor()
        
        return true
    }
}

