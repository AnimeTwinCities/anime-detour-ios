//
//  ConModelsController_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

import ConScheduleKit

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: CoreDataController!

extension CoreDataController {
    class var sharedInstance: CoreDataController {
        dispatch_once(&_onceToken) {
            _sharedInstance = CoreDataController()
        }

        return _sharedInstance
    }
}
