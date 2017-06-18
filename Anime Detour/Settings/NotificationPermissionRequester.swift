//
//  NotificationPermissionRequester.swift
//  Anime Detour
//
//  Created by Brendon Justin on 9/21/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation
import UserNotifications

@available(iOS 8, *)
class NotificationPermissionRequester {
    let internalSettings: InternalSettings
    let sessionSettings: SessionSettings
    
    var delegate: NotificationPermissionRequesterDelegate?
    var enableSessionNotificationsOnNotificationsEnabled = false
    
    /**
    Indicates whether the user has given permission to send local notifications.
    Must be set early in `application:didFinishLaunchingWithOptions:`.
    */
    var localNotificationsAllowed: Bool = false {
        didSet {
            let allowed = localNotificationsAllowed
            
            if allowed {
                if enableSessionNotificationsOnNotificationsEnabled {
                    sessionSettings.favoriteSessionAlerts = true
                }
                
                enableSessionNotificationsOnNotificationsEnabled = false
            }
        }
    }
    
    init(internalSettings: InternalSettings, sessionSettings: SessionSettings) {
        self.internalSettings = internalSettings
        self.sessionSettings = sessionSettings
    }
    
    /**
    Request permission to display the types of notifications we want to display.
    */
    func requestNotificationPermissions(completionHandler: @escaping (Bool, Error?) -> Void) {
        internalSettings.askedSystemToEnableNotifications = true
        
        let options: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completionHandler)
    }
    
    /**
     Ask the user if they'd like to enable notifications for upcoming favorited Sessions.
     Only requests push notification permissions if they agree, so `completionHandler` is not called
     if they do not agree.
     */
    func askEnableSessionNotifications(completionHandler: @escaping (Bool, Error?) -> Void) {
        let alertController = UIAlertController(title: "Session Notifications", message: "Enable alerts for favorite sessions? You'll have to allow notifications from the app.", preferredStyle: UIAlertControllerStyle.alert)
        
        let accept = UIAlertAction(title: "Enable", style: UIAlertActionStyle.default) { (action: UIAlertAction) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.requestNotificationPermissions(completionHandler: completionHandler)
        }
        let cancel = UIAlertAction(title: "Not Now", style: UIAlertActionStyle.cancel)  { (action: UIAlertAction) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.sessionSettings.favoriteSessionAlerts = false
            return
        }
        
        alertController.addAction(cancel)
        alertController.addAction(accept)
        
        delegate?.notificationPermissionRequester(self, wantsToPresentAlertController: alertController)
    }
}

protocol NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(_ requester: NotificationPermissionRequester, wantsToPresentAlertController: UIAlertController)
}
