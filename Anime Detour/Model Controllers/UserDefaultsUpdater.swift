//
//  UserDefaultsController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 6/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

protocol UserDefaultsUpdater {
    var userDefaults: NSUserDefaults { get }
    
    func updateDefaultsAndNotifyForPropertyUpdated<T: protocol<AnyObject, Equatable>>(newValue: T, oldValue: T,
        userDefaultsKey: String, delegateCallback: (T -> Void)?)
    
    // bool version
    func updateDefaultsAndNotifyForPropertyUpdated(newValue: Bool, oldValue: Bool,
        userDefaultsKey: String, delegateCallback: (Bool -> Void)?)
}

extension UserDefaultsUpdater {
    func updateDefaultsAndNotifyForPropertyUpdated<T: protocol<AnyObject, Equatable>>(newValue: T, oldValue: T,
        userDefaultsKey: String, delegateCallback: (T -> Void)?) {
            if self.userDefaults.valueForKey(userDefaultsKey) as! T != newValue {
                self.userDefaults.setValue(newValue, forKey: userDefaultsKey)
            }
            
            if newValue != oldValue {
                delegateCallback?(newValue)
            }
    }
    
    func updateDefaultsAndNotifyForPropertyUpdated(newValue: Bool, oldValue: Bool,
        userDefaultsKey: String, delegateCallback: (Bool -> Void)?) {
            if self.userDefaults.boolForKey(userDefaultsKey) != newValue {
                self.userDefaults.setBool(newValue, forKey: userDefaultsKey)
            }
            
            if newValue != oldValue {
                delegateCallback?(newValue)
            }
    }
}
