//
//  ScheduleAPIClient_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

import AnimeDetourAPI

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: AnimeDetourAPIClient!

extension AnimeDetourAPIClient {
    class var sharedInstance: AnimeDetourAPIClient {
        dispatch_once(&_onceToken) {
            _sharedInstance = AnimeDetourAPIClient()
        }
        
        return _sharedInstance
    }
}
