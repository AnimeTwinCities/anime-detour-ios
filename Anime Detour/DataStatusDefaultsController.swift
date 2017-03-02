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
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        
        defaultsUpdater = DataStatusDefaultsUpdater(userDefaults: userDefaults)
        
        let defaultUserDefaults = [
            // The 2017 app and later no longer require database cleanup,
            // so it is the most recent version of interest for database checks.
            DataStatusDefaultsKeys.DatabaseCheckedVersionKey : "2017",
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
