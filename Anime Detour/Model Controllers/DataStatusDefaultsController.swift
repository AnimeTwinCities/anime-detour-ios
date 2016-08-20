//
//  DataStatusDefaultsController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 6/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

class DataStatusDefaultsController {
    fileprivate struct DataStatusDefaultsKeys {
        fileprivate static let DatabaseCheckedVersionKey = "databaseCheckedVersionKey"
        fileprivate static let GuestsFetchRequiredKey = "guestsFetchRequiredKey"
        fileprivate static let SessionsFetchRequiredKey = "sessionsFetchRequiredKey"
        fileprivate static let LastGuestsClearDateKey = "lastGuestsClearDateKey"
        fileprivate static let LastSessionsClearDateKey = "lastSessionsClearDateKey"
    }
    
    fileprivate let userDefaults: UserDefaults
    fileprivate let defaultsUpdater: DataStatusDefaultsUpdater
    
    /**
     Track the version of the app that last checked the database, in case it
     needs any attention. For example, if the SQLite file was renamed and any existing
     file must be renamed or deleted.
     */
    var databaseCheckedVersionKey: String {
        get {
            return userDefaults.string(forKey: DataStatusDefaultsKeys.DatabaseCheckedVersionKey)!
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: databaseCheckedVersionKey, userDefaultsKey: DataStatusDefaultsKeys.DatabaseCheckedVersionKey, delegateCallback: nil)
        }
    }
    var guestsFetchRequired: Bool {
        get {
            return userDefaults.bool(forKey: DataStatusDefaultsKeys.GuestsFetchRequiredKey)
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: guestsFetchRequired,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.GuestsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var sessionsFetchRequired: Bool {
        get {
            return userDefaults.bool(forKey: DataStatusDefaultsKeys.SessionsFetchRequiredKey)
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: sessionsFetchRequired,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.SessionsFetchRequiredKey, delegateCallback: nil)
        }
    }
    var lastGuestsClearDate: Date {
        get {
            return userDefaults.value(forKey: DataStatusDefaultsKeys.LastGuestsClearDateKey) as! Date
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: lastGuestsClearDate,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.LastGuestsClearDateKey, delegateCallback: nil)
        }
    }
    var lastSessionsClearDate: Date {
        get {
            return userDefaults.value(forKey: DataStatusDefaultsKeys.LastSessionsClearDateKey) as! Date
        }
        set {
            defaultsUpdater.updateDefaultsAndNotifyForPropertyUpdated(newValue, oldValue: lastSessionsClearDate,
                                                                      userDefaultsKey: DataStatusDefaultsKeys.LastSessionsClearDateKey, delegateCallback: nil)
        }
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        
        defaultsUpdater = DataStatusDefaultsUpdater(userDefaults: userDefaults)
        
        // Default last-must-be-cleared dates. Set to early on 3/25/2016 UTC.
        let defaultGuestsClearDate: Date = Date(timeIntervalSince1970: 1458873747)
        let defaultSessionsClearDate: Date = Date(timeIntervalSince1970: 1458873747)
        
        let defaultUserDefaults = [
            // 2.1 is the last version that used the "Anime Detour API" framework,
            // and thus the last version which did not need a database cleanup.
            DataStatusDefaultsKeys.DatabaseCheckedVersionKey : "2.1",
            DataStatusDefaultsKeys.GuestsFetchRequiredKey : NSNumber(value: true),
            DataStatusDefaultsKeys.SessionsFetchRequiredKey : NSNumber(value: true),
            DataStatusDefaultsKeys.LastGuestsClearDateKey : defaultGuestsClearDate,
            DataStatusDefaultsKeys.LastSessionsClearDateKey : defaultSessionsClearDate,
        ] as [String : Any]
        
        userDefaults.register(defaults: defaultUserDefaults)
    }
    
    func synchronizeDefaults() {
        userDefaults.synchronize()
    }
    
}

// Use the default implementations of `UserDefaultsUpdater` methods
private class DataStatusDefaultsUpdater: UserDefaultsUpdater {
    fileprivate let userDefaults: UserDefaults
    
    required init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}
