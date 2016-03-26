//
//  InternalSettings.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/20/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

/**
Settings which should not be user-visible.
*/
final class InternalSettings {
    struct InternalSettingsUserDefaultsKeys {
        static let AskedNotificationsKey = "AskedNotificationsKey"
        static let AskedSystemNotificationsKey = "AskedSystemNotificationsKey"
    }
    
    private let userDefaults: NSUserDefaults
    var askedToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedNotificationsKey
            let newValue = askedToEnableNotifications
            
            if userDefaults.boolForKey(key) != newValue {
                userDefaults.setBool(newValue, forKey: key)
            }
        }
    }
    
    var askedSystemToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey
            let newValue = askedSystemToEnableNotifications
            
            if userDefaults.boolForKey(key) != newValue {
                userDefaults.setBool(newValue, forKey: key)
            }
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        
        registerDefaults(userDefaults)
        updateAskedForNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InternalSettings.defaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: userDefaults)
    }
    
    private func registerDefaults(userDefaults: NSUserDefaults) {
        let defaults = [
            InternalSettingsUserDefaultsKeys.AskedNotificationsKey : NSNumber(bool: false),
            InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey : NSNumber(bool: false),
        ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    private func updateAskedForNotifications() {
        let didAsk = userDefaults.boolForKey(InternalSettingsUserDefaultsKeys.AskedNotificationsKey)
        askedToEnableNotifications = didAsk
        
        let didAskSystem = userDefaults.boolForKey(InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey)
        askedSystemToEnableNotifications = didAskSystem
    }
    
    @objc private func defaultsDidChange(notification: NSNotification) {
        updateAskedForNotifications()
    }
}
