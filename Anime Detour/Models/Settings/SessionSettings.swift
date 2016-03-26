//
//  Settings.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/19/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

import FXForms

/**
Settings which should be presented to the user.

Specify the runtime class name for the benefit of FXForms.
*/
@objc(SessionSettings) final class SessionSettings: NSObject, FXForm {
    struct SessionSettingsUserDefaultsKeys {
        static let FavoriteSessionAlertsKey = "SettingsFavoriteSessionAlertsKey"
    }
    
    private let userDefaults: NSUserDefaults
    
    weak var delegate: SessionSettingsDelegate?
    
    var favoriteSessionAlerts: Bool = false {
        didSet {
            let key = SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey
            let newValue = favoriteSessionAlerts
            if userDefaults.boolForKey(key) != newValue {
                userDefaults.setBool(newValue, forKey: key)
            }
            
            if newValue != oldValue {
                delegate?.didChangeSessionNotificationsSetting(newValue)
            }
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        super.init()
        
        registerDefaults(userDefaults)
        updateSessionNotificationsEnabled()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SessionSettings.userDefaultsChanged(_:)), name: NSUserDefaultsDidChangeNotification, object: userDefaults)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: userDefaults)
    }
    
    private func registerDefaults(userDefaults: NSUserDefaults) {
        let defaults = [
            SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey : NSNumber(bool: false),
        ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    private func updateSessionNotificationsEnabled() {
        let notificationsEnabled = userDefaults.boolForKey(SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey)
        favoriteSessionAlerts = notificationsEnabled
    }
    
    @objc private func userDefaultsChanged(notification: NSNotification) {
        updateSessionNotificationsEnabled()
    }
}

protocol SessionSettingsDelegate: class {
    func didChangeSessionNotificationsSetting(enabled: Bool)
}
