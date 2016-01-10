//
//  ScheduleAPIClient_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

import AnimeDetourSchedorgAPI

extension AnimeDetourSchedorgAPIClient {
    static let sharedInstance: AnimeDetourSchedorgAPIClient = AnimeDetourSchedorgAPIClient()
}
