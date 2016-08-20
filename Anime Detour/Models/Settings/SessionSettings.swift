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
    
    fileprivate let userDefaults: UserDefaults
    
    weak var delegate: SessionSettingsDelegate?
    
    var favoriteSessionAlerts: Bool = false {
        didSet {
            let key = SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey
            let newValue = favoriteSessionAlerts
            if userDefaults.bool(forKey: key) != newValue {
                userDefaults.set(newValue, forKey: key)
            }
            
            if newValue != oldValue {
                delegate?.didChangeSessionNotificationsSetting(newValue)
            }
        }
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        super.init()
        
        registerDefaults(userDefaults)
        updateSessionNotificationsEnabled()
        NotificationCenter.default.addObserver(self, selector: #selector(SessionSettings.userDefaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: userDefaults)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: userDefaults)
    }
    
    fileprivate func registerDefaults(_ userDefaults: UserDefaults) {
        let defaults = [
            SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey : NSNumber(value: false),
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    fileprivate func updateSessionNotificationsEnabled() {
        let notificationsEnabled = userDefaults.bool(forKey: SessionSettingsUserDefaultsKeys.FavoriteSessionAlertsKey)
        favoriteSessionAlerts = notificationsEnabled
    }
    
    @objc fileprivate func userDefaultsChanged(_ notification: Notification) {
        updateSessionNotificationsEnabled()
    }
}

protocol SessionSettingsDelegate: class {
    func didChangeSessionNotificationsSetting(_ enabled: Bool)
}
