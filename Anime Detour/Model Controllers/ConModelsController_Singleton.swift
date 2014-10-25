//
//  ConModelsController_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: ConModelsController!

extension ConModelsController {
    class var sharedInstance: ConModelsController {
        dispatch_once(&_onceToken) {
            _sharedInstance = ConModelsController()
        }

        return _sharedInstance
    }
}
