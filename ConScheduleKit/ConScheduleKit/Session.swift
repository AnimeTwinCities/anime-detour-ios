//
//  Session.swift
//  ConScheduleKit
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

public class Session {
    public var key: String = ""
    public var active: Bool = false
    public var name: String = ""
    public var start: NSDate = NSDate(timeIntervalSince1970: 0)
    public var end: NSDate = NSDate(timeIntervalSince1970: 1)
    public var type: String = ""
    public var description: String = ""
    public var mediaURL: String = ""
    public var seats: UInt = 0
    public var goers: UInt = 0
    public var inviteOnly: Bool = false
    public var venue: String = ""
    public var address: String = ""
    public var sessionID: String = ""
    public var venueID: String = ""
    
    public init() {
        
    }
}