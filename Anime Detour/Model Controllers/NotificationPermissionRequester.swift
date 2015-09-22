//
//  NotificationPermissionRequester.swift
//  Anime Detour
//
//  Created by Brendon Justin on 9/21/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

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
            let allowed = self.localNotificationsAllowed
            
            if allowed {
                if self.enableSessionNotificationsOnNotificationsEnabled {
                    self.sessionSettings.favoriteSessionAlerts = true
                }
                
                self.enableSessionNotificationsOnNotificationsEnabled = false
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
    func requestNotificationPermissions() {
        self.internalSettings.askedSystemToEnableNotifications = true
        
        let application = UIApplication.sharedApplication()
        
        // Request all permissions
        let noteTypes: UIUserNotificationType = [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge]
        let noteSettings = UIUserNotificationSettings(forTypes: noteTypes, categories: nil)
        application.registerUserNotificationSettings(noteSettings)
    }
    
    /**
    Ask the user if they'd like to enable notifications for upcoming favorited Sessions.
    Only requests push notification permissions if they agree.
    */
    func askEnableSessionNotifications() {
        let alertController = UIAlertController(title: "Session Notifications", message: "Enable alerts for favorite sessions? You'll have to allow notifications from the app.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let accept = UIAlertAction(title: "Enable", style: UIAlertActionStyle.Default) { (action: UIAlertAction) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.requestNotificationPermissions()
        }
        let cancel = UIAlertAction(title: "Not Now", style: UIAlertActionStyle.Cancel)  { (action: UIAlertAction) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.sessionSettings.favoriteSessionAlerts = false
            return
        }
        
        alertController.addAction(cancel)
        alertController.addAction(accept)
        
        self.delegate?.notificationPermissionRequester(self, wantsToPresentAlertController: alertController)
    }
}

protocol NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(requester: NotificationPermissionRequester, wantsToPresentAlertController: UIAlertController)
}
