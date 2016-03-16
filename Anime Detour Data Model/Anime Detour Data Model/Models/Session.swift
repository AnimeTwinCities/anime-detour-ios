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
    public static let entityName: String = "Session"
    
    public enum Keys: String {
        case bannerURL
        case bookmarked
        case category
        case hosts
        case name
        case startTime = "start"
        case tags
        case sessionID
    }
    
    @NSManaged public var sessionID: String
    @NSManaged public var name: String
    @NSManaged public var sessionDescription: String
    @NSManaged public var start: NSDate
    @NSManaged public var end: NSDate
    @NSManaged public var category: String
    @NSManaged public var room: String
    @NSManaged public var bookmarked: Bool
    
    public var bannerURL: NSURL? {
        get {
            willAccessValueForKey(Keys.bannerURL.rawValue)
            defer {
                didAccessValueForKey(Keys.bannerURL.rawValue)
            }
            
            return primitiveBannerURL.flatMap { NSURL(string: $0) }
        }
        set {
            willChangeValueForKey(Keys.bannerURL.rawValue)
            defer {
                didChangeValueForKey(Keys.bannerURL.rawValue)
            }
            
            primitiveBannerURL = newValue?.absoluteString
        }
    }
    @NSManaged var primitiveBannerURL: String?
    
    public var hosts: [String] {
        get {
            willAccessValueForKey(Keys.hosts.rawValue)
            defer {
                didAccessValueForKey(Keys.hosts.rawValue)
            }
            return primitiveHosts.componentsSeparatedByString("SPLIT, ")
        }
        set {
            willChangeValueForKey(Keys.hosts.rawValue)
            defer {
                didChangeValueForKey(Keys.hosts.rawValue)
            }
            
            primitiveHosts = newValue.joinWithSeparator("SPLIT, ")
        }
    }
    @NSManaged var primitiveHosts: String
    
    public var tags: [String] {
        get {
            willAccessValueForKey(Keys.tags.rawValue)
            defer {
                didAccessValueForKey(Keys.tags.rawValue)
            }
            return primitiveTags.componentsSeparatedByString("SPLIT, ")
        }
        set {
            willChangeValueForKey(Keys.tags.rawValue)
            defer {
                didChangeValueForKey(Keys.tags.rawValue)
            }
            primitiveTags = newValue.joinWithSeparator("SPLIT, ")
        }
    }
    @NSManaged var primitiveTags: String
    
    override public var description: String {
        return "Session: \(name) - \(sessionDescription)"
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        // set empty default strings for String properties
        sessionID = ""
        name = ""
        sessionDescription = ""
        category = ""
        room = ""
    }
}