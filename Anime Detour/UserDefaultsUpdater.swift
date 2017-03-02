//
//  UserDefaultsController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 6/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

protocol UserDefaultsUpdater {
    var userDefaults: UserDefaults { get }
    
    /// If `newValue` is different than the existing value corresponding to `userDefaultsKey`,
    /// update the value in `userDefaults` then call `delegateCallback`. Otherwise, do nothing.
    func updateDefaultsAndNotifyForPropertyUpdated<T: Hashable>(_ newValue: T, oldValue: T,
        userDefaultsKey: String, delegateCallback: ((T) -> Void)?)
    
    // bool version
    /// If `newValue` is different than the existing value corresponding to `userDefaultsKey`,
    /// update the value in `userDefaults` then call `delegateCallback`. Otherwise, do nothing.
    /// - SeeAlso: updateDefaultsAndNotifyForPropertyUpdated
    func updateDefaultsAndNotifyForPropertyUpdated(_ newValue: Bool, oldValue: Bool,
        userDefaultsKey: String, delegateCallback: ((Bool) -> Void)?)
}

extension UserDefaultsUpdater {
    func updateDefaultsAndNotifyForPropertyUpdated<T: Hashable>(_ newValue: T, oldValue: T,
        userDefaultsKey: String, delegateCallback: ((T) -> Void)?) {
            if userDefaults.value(forKey: userDefaultsKey) as! T != newValue {
                userDefaults.setValue(newValue, forKey: userDefaultsKey)
            }
            
            if newValue != oldValue {
                delegateCallback?(newValue)
            }
    }
    
    func updateDefaultsAndNotifyForPropertyUpdated(_ newValue: Bool, oldValue: Bool,
        userDefaultsKey: String, delegateCallback: ((Bool) -> Void)?) {
            if userDefaults.bool(forKey: userDefaultsKey) != newValue {
                userDefaults.set(newValue, forKey: userDefaultsKey)
            }
            
            if newValue != oldValue {
                delegateCallback?(newValue)
            }
    }
}
