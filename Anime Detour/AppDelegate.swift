//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Main logic
    private var tabController: UITabBarController!
    private lazy var appCoordinator: AppCoordinator = { () -> AppCoordinator in
        return AppCoordinator(window: self.window!, tabBarController: self.tabController)
    }()
    
    // MARK: - Application Delegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        tabController = window!.rootViewController as! UITabBarController
        appCoordinator.start()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return appCoordinator.open(url, options: options)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        #if os(iOS)
            appCoordinator.didBecomeActive()
        #endif
    }
}
