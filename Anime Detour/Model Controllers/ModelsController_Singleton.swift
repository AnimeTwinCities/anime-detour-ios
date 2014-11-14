//
//  ConModelsController_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import ConScheduleKit

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: ModelsController!

extension ModelsController {
    class var sharedInstance: ModelsController {
        dispatch_once(&_onceToken) {
            _sharedInstance = ModelsController()
        }

        return _sharedInstance
    }
}
