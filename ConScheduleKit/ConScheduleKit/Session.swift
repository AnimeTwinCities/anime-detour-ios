//
//  Session.swift
//  ConScheduleKit
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import CoreData

public class Session: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var active: Bool
    @NSManaged public var name: String
    @NSManaged public var start: NSDate
    @NSManaged public var end: NSDate
    @NSManaged public var type: String
    @NSManaged public var sessionDescription: String
    @NSManaged public var mediaURL: String
    @NSManaged public var seats: UInt32
    @NSManaged public var goers: UInt32
    @NSManaged public var inviteOnly: Bool
    @NSManaged public var venue: String
    @NSManaged public var address: String
    @NSManaged public var sessionID: String
    @NSManaged public var venueID: String

    override public var description: String {
        return "Session: \(name) - \(sessionDescription)"
    }

    public override func awakeFromInsert() {
        // set empty default strings for String properties
        self.key = ""
        self.name = ""
        self.type = ""
        self.sessionDescription = ""
        self.mediaURL = ""
        self.venue = ""
        self.address = ""
        self.sessionID = ""
        self.venueID = ""
    }
}