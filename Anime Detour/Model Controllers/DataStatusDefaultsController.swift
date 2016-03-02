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
        didSet {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(databaseCheckedVersionKey as NSString, oldValue: oldValue, userDefaultsKey: DataStatusDefaultsKeys.DatabaseCheckedVersionKey, delegateCallback: nil)
        }
    }
    var guestsFetchRequired: Bool {
        didSet {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(guestsFetchRequired, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.GuestsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var sessionsFetchRequired: Bool {
        didSet {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(sessionsFetchRequired, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.SessionsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var lastGuestsClearDate: NSDate {
        didSet {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(lastGuestsClearDate, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.LastGuestsClearDateKey, delegateCallback: nil)
        }
    }
    var lastSessionsClearDate: NSDate {
        didSet {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(lastSessionsClearDate, oldValue: oldValue,
                userDefaultsKey: DataStatusDefaultsKeys.LastSessionsClearDateKey, delegateCallback: nil)
        }
    }
    
    init(userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.userDefaults = userDefaults
        
        defaultsUpdater = DataStatusDefaultsUpdater(userDefaults: userDefaults)
        
        // Default last-must-be-cleared dates, set way in the past.
        let defaultGuestsClearDate: NSDate = NSDate(timeIntervalSince1970: 0)
        let defaultSessionsClearDate: NSDate = NSDate(timeIntervalSince1970: 0)
        
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
        
        databaseCheckedVersionKey = userDefaults.stringForKey(DataStatusDefaultsKeys.DatabaseCheckedVersionKey)!
        guestsFetchRequired = userDefaults.boolForKey(DataStatusDefaultsKeys.GuestsFetchRequiredKey)
        sessionsFetchRequired = userDefaults.boolForKey(DataStatusDefaultsKeys.SessionsFetchRequiredKey)
        lastGuestsClearDate = userDefaults.valueForKey(DataStatusDefaultsKeys.LastGuestsClearDateKey) as! NSDate
        lastSessionsClearDate = userDefaults.valueForKey(DataStatusDefaultsKeys.LastSessionsClearDateKey) as! NSDate
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
