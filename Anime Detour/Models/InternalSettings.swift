//
//  InternalSettings.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/20/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

final class InternalSettings {
    struct InternalSettingsUserDefaultsKeys {
        static let AskedNotificationsKey = "AskedNotificationsKey"
        static let AskedSystemNotificationsKey = "AskedSystemNotificationsKey"
    }
    
    private let userDefaults: NSUserDefaults
    var askedToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedNotificationsKey
            let newValue = self.askedToEnableNotifications
            
            if self.userDefaults.boolForKey(key) != newValue {
                self.userDefaults.setBool(newValue, forKey: key)
            }
        }
    }
    
    var askedSystemToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey
            let newValue = self.askedSystemToEnableNotifications
            
            if self.userDefaults.boolForKey(key) != newValue {
                self.userDefaults.setBool(newValue, forKey: key)
            }
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        
        self.registerDefaults(userDefaults)
        self.updateAskedForNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("defaultsDidChange:"), name: NSUserDefaultsDidChangeNotification, object: userDefaults)
    }
    
    private func registerDefaults(userDefaults: NSUserDefaults) {
        let defaults = [
            InternalSettingsUserDefaultsKeys.AskedNotificationsKey : NSNumber(bool: false),
            InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey : NSNumber(bool: false),
        ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    private func updateAskedForNotifications() {
        let didAsk = self.userDefaults.boolForKey(InternalSettingsUserDefaultsKeys.AskedNotificationsKey)
        self.askedToEnableNotifications = didAsk
        
        let didAskSystem = self.userDefaults.boolForKey(InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey)
        self.askedSystemToEnableNotifications = didAskSystem
    }
    
    @objc private func defaultsDidChange(notification: NSNotification) {
        self.updateAskedForNotifications()
    }
}
