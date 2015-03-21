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
            let newValue = self.favoriteSessionAlerts
            if self.userDefaults.boolForKey(key) != newValue {
                self.userDefaults.setBool(newValue, forKey: key)
            }
            
            if newValue != oldValue {
                self.delegate?.didChangeSessionNotificationsSetting(newValue)
            }
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        super.init()
        
        self.registerDefaults(userDefaults)
        self.updateSessionNotificationsEnabled()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsChanged:"), name: NSUserDefaultsDidChangeNotification, object: self.userDefaults)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: self.userDefaults)
    }
    
    private func registerDefaults(userDefaults: NSUserDefaults) {
        let defaults = [
            SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey : NSNumber(bool: false),
        ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    private func updateSessionNotificationsEnabled() {
        let notificationsEnabled = self.userDefaults.boolForKey(SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey)
        self.favoriteSessionAlerts = notificationsEnabled
    }
    
    @objc private func userDefaultsChanged(notification: NSNotification) {
        self.updateSessionNotificationsEnabled()
    }
}

protocol SessionSettingsDelegate: class {
    func didChangeSessionNotificationsSetting(enabled: Bool)
}
