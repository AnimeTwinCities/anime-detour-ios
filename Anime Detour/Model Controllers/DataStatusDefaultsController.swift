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
        private static let DatabaseCheckedVersionKey = "databaseCheckedVersionKey"
        private static let GuestsFetchRequiredKey = "guestsFetchRequiredKey"
        private static let SessionsFetchRequiredKey = "sessionsFetchRequiredKey"
        private static let LastGuestsClearDateKey = "lastGuestsClearDateKey"
        private static let LastSessionsClearDateKey = "lastSessionsClearDateKey"
    }
    
    private let userDefaults: NSUserDefaults
    private let defaultsUpdater: DataStatusDefaultsUpdater
    
    /**
     Track the version of the app that last checked the database, in case it
     needs any attention. For example, if the SQLite file was renamed and any existing
     file must be renamed or deleted.
     */
    var databaseCheckedVersionKey: String {
        get {
            return userDefaults.stringForKey(DataStatusDefaultsKeys.DatabaseCheckedVersionKey)!
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: databaseCheckedVersionKey as NSString, userDefaultsKey: DataStatusDefaultsKeys.DatabaseCheckedVersionKey, delegateCallback: nil)
        }
    }
    var guestsFetchRequired: Bool {
        get {
            return userDefaults.boolForKey(DataStatusDefaultsKeys.GuestsFetchRequiredKey)
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: guestsFetchRequired,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.GuestsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var sessionsFetchRequired: Bool {
        get {
            return userDefaults.boolForKey(DataStatusDefaultsKeys.SessionsFetchRequiredKey)
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: sessionsFetchRequired,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.SessionsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var lastGuestsClearDate: NSDate {
        get {
            return userDefaults.valueForKey(DataStatusDefaultsKeys.LastGuestsClearDateKey) as! NSDate
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: lastGuestsClearDate,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.LastGuestsClearDateKey, delegateCallback: nil)
        }
    }
    var lastSessionsClearDate: NSDate {
        get {
            return userDefaults.valueForKey(DataStatusDefaultsKeys.LastSessionsClearDateKey) as! NSDate
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: lastSessionsClearDate,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.LastSessionsClearDateKey, delegateCallback: nil)
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        
        defaultsUpdater = DataStatusDefaultsUpdater(userDefaults: userDefaults)
        
        // Default last-must-be-cleared dates. Set to early on 3/25/2016 UTC.
        let defaultGuestsClearDate: NSDate = NSDate(timeIntervalSince1970: 1458873747)
        let defaultSessionsClearDate: NSDate = NSDate(timeIntervalSince1970: 1458873747)
        
        let defaultUserDefaults = [
            // 2.1 is the last version that used the "Anime Detour API" framework,
            // and thus the last version which did not need a database cleanup.
            DataStatusDefaultsKeys.DatabaseCheckedVersionKey : "2.1",
            DataStatusDefaultsKeys.GuestsFetchRequiredKey : NSNumber(bool: true),
            DataStatusDefaultsKeys.SessionsFetchRequiredKey : NSNumber(bool: true),
            DataStatusDefaultsKeys.LastGuestsClearDateKey : defaultGuestsClearDate,
            DataStatusDefaultsKeys.LastSessionsClearDateKey : defaultSessionsClearDate,
        ]
        
        userDefaults.registerDefaults(defaultUserDefaults)
    }
    
    func synchronizeDefaults() {
        userDefaults.synchronize()
    }
    
}

// Use the default implementations of `UserDefaultsUpdater` methods
private class DataStatusDefaultsUpdater: UserDefaultsUpdater {
    private let userDefaults: NSUserDefaults
    
    required init(userDefaults: NSUserDefaults) {
        self.userDefaults = userDefaults
    }
}
