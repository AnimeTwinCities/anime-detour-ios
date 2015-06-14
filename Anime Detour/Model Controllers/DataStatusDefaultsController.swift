//
//  DataStatusDefaultsController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 6/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

class DataStatusDefaultsController {
    private struct DataStatusDefaultsKeys {
        private static let GuestsFetchRequiredKey = "guestsFetchRequiredKey"
        private static let SessionsFetchRequiredKey = "sessionsFetchRequiredKey"
        private static let LastGuestsClearDateKey = "lastGuestsClearDateKey"
        private static let LastSessionsClearDateKey = "lastSessionsClearDateKey"
    }
    
    private let userDefaults: NSUserDefaults
    private let defaultsUpdater: DataStatusDefaultsUpdater
    
    var guestsFetchRequired: Bool {
        didSet {
            self.defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(self.guestsFetchRequired, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.GuestsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var sessionsFetchRequired: Bool {
        didSet {
            self.defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(self.sessionsFetchRequired, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.SessionsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var lastGuestsClearDate: NSDate {
        didSet {
            self.defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(self.lastGuestsClearDate, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.LastGuestsClearDateKey, delegateCallback: nil)
        }
    }
    var lastSessionsClearDate: NSDate {
        didSet {
            self.defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(self.lastSessionsClearDate, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.LastSessionsClearDateKey, delegateCallback: nil)
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        self.defaultsUpdater = DataStatusDefaultsUpdater(userDefaults: self.userDefaults)
        
        // Default last-must-be-cleared dates, set way in the past.
        let defaultGuestsClearDate: NSDate = NSDate(timeIntervalSince1970: 0)
        let defaultSessionsClearDate: NSDate = NSDate(timeIntervalSince1970: 0)
        
        let defaultUserDefaults = [
            DataStatusDefaultsKeys.GuestsFetchRequiredKey : NSNumber(bool: true),
            DataStatusDefaultsKeys.SessionsFetchRequiredKey : NSNumber(bool: true),
            DataStatusDefaultsKeys.LastGuestsClearDateKey : defaultGuestsClearDate,
            DataStatusDefaultsKeys.LastSessionsClearDateKey : defaultSessionsClearDate,
        ]
        
        userDefaults.registerDefaults(defaultUserDefaults)
        
        self.guestsFetchRequired = userDefaults.boolForKey(DataStatusDefaultsKeys.GuestsFetchRequiredKey)
        self.sessionsFetchRequired = userDefaults.boolForKey(DataStatusDefaultsKeys.SessionsFetchRequiredKey)
        self.lastGuestsClearDate = userDefaults.valueForKey(DataStatusDefaultsKeys.LastGuestsClearDateKey) as! NSDate
        self.lastSessionsClearDate = userDefaults.valueForKey(DataStatusDefaultsKeys.LastSessionsClearDateKey) as! NSDate
    }
    
    func synchronizeDefaults() {
        self.userDefaults.synchronize()
    }
    
}

// Use the default implementations of `UserDefaultsUpdater` methods
private class DataStatusDefaultsUpdater: UserDefaultsUpdater {
    private let userDefaults: NSUserDefaults
    
    required init(userDefaults: NSUserDefaults) {
        self.userDefaults = userDefaults
    }
}

