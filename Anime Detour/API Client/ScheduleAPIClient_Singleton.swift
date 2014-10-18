//
//  ScheduleAPIClient_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import ConScheduleKit

private var _onceToken: dispatch_once_t = 0
private var _sharedInstance: ScheduleAPIClient!

extension ScheduleAPIClient {
    class var sharedInstance: ScheduleAPIClient {
        dispatch_once(&_onceToken) {
            let configPath: String! = NSBundle.mainBundle().pathForResource("API Details", ofType: "plist")
            let config = NSDictionary(contentsOfFile: configPath) as [String:String]!
            
            let subdomain = config["Subdomain"]!
            let apiKey = config["API Key"]!
            let timezoneName = config["Time Zone"]!
            _sharedInstance = ScheduleAPIClient(subdomain: subdomain, apiKey: apiKey, conLocationTimeZone: NSTimeZone(name: timezoneName)!)
        }
        
        return _sharedInstance
    }
}
