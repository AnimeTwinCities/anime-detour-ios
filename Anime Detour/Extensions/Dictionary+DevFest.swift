//
//  Dictionary+DevFest.swift
//  DevFest
//
//  Created by Brendon Justin on 12/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

extension Dictionary {
    subscript(key: Key, defaulting defaultValue: Value) -> Value {
        get {
            return self[key] ?? defaultValue
        }
        set {
            self[key] = newValue
        }
    }
}
