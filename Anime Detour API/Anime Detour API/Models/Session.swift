//
//  Session.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import Foundation

import CoreData

public class Session: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var active: Bool
    @NSManaged public var bookmarked: Bool
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

    class public var entityName: String {
        return "Session"
    }

    override public var description: String {
        return "Session: \(name) - \(sessionDescription)"
    }

    /// All of the types of this Session. Ordered by importance. Assumes `type` is a
    /// comma-separated list of types.
    public var types: [String] {
        get {
            return self.type.componentsSeparatedByString(",")
        }
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()

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