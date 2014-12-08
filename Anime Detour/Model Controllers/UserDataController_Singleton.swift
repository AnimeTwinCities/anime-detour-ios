//
//  UserDataController_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/2/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: UserDataController!

extension UserDataController {
    class var sharedInstance: UserDataController {
        dispatch_once(&_onceToken) {
            _sharedInstance = UserDataController()
        }

        return _sharedInstance
    }
}
