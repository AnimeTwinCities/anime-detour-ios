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
*/
final class UserVisibleSettings: NSObject, FXForm {
    struct UserVisibleSettingsUserDefaultsKeys {
        static let FavoriteSessionAlertsKey = "SettingsFavoriteSessionAlertsKey"
    }
    
    private let userDefaults: NSUserDefaults
    
    weak var delegate: UserVisibleSettingsDelegate?
    
    var favoriteSessionAlerts: Bool = false {
        didSet {
            let key = UserVisibleSettingsUserDefaultsKeys.FavoriteSessionAlertsKey
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
            UserVisibleSettingsUserDefaultsKeys.FavoriteSessionAlertsKey : NSNumber(bool: false),
        ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    private func updateSessionNotificationsEnabled() {
        let notificationsEnabled = self.userDefaults.boolForKey(UserVisibleSettingsUserDefaultsKeys.FavoriteSessionAlertsKey)
        self.favoriteSessionAlerts = notificationsEnabled
    }
    
    @objc private func userDefaultsChanged(notification: NSNotification) {
        self.updateSessionNotificationsEnabled()
    }
}

protocol UserVisibleSettingsDelegate: class {
    func didChangeSessionNotificationsSetting(enabled: Bool)
}
