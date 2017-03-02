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
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

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
    
    #if os(iOS)
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        appCoordinator.didRegister(with: notificationSettings)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        appCoordinator.didReceive(notification: notification)
    }
    #endif
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        #if os(iOS)
            appCoordinator.didBecomeActive()
        #endif
    }
}
