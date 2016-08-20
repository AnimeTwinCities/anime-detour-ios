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
    
    fileprivate let userDefaults: UserDefaults
    var askedToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedNotificationsKey
            let newValue = askedToEnableNotifications
            
            if userDefaults.bool(forKey: key) != newValue {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
    
    var askedSystemToEnableNotifications: Bool = false {
        didSet {
            let key = InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey
            let newValue = askedSystemToEnableNotifications
            
            if userDefaults.bool(forKey: key) != newValue {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        
        registerDefaults(userDefaults)
        updateAskedForNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(InternalSettings.defaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: userDefaults)
    }
    
    fileprivate func registerDefaults(_ userDefaults: UserDefaults) {
        let defaults = [
            InternalSettingsUserDefaultsKeys.AskedNotificationsKey : NSNumber(value: false),
            InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey : NSNumber(value: false),
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    fileprivate func updateAskedForNotifications() {
        let didAsk = userDefaults.bool(forKey: InternalSettingsUserDefaultsKeys.AskedNotificationsKey)
        askedToEnableNotifications = didAsk
        
        let didAskSystem = userDefaults.bool(forKey: InternalSettingsUserDefaultsKeys.AskedSystemNotificationsKey)
        askedSystemToEnableNotifications = didAskSystem
    }
    
    @objc fileprivate func defaultsDidChange(_ notification: Notification) {
        updateAskedForNotifications()
    }
}
