//
//  Session.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import Foundation

import CoreData
import UIKit

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
    
    public struct Category {
        private enum CategoryName: String {
            case cosplayPhotoshoot = "Cosplay Photoshoot"
            case electronicGaming = "Electronic Gaming"
            case event = "Event"
            case guestSigning = "Guest Signing"
            case hoursOfOperation = "Hours of Operation"
            case panel = "Panel"
            case roomParty = "Room Party"
            case tabletopGaming = "Tabletop Gaming"
            case video = "Video"
            case workshop = "Workshop"
            
            var color: UIColor {
                let hex: Int
                switch self {
                case .cosplayPhotoshoot:
                    hex = 0xffC0CA33
                case .electronicGaming:
                    hex = 0xff3949AB
                case .event:
                    hex = 0xff43A047
                case .guestSigning:
                    hex = 0xff8E24AA
                case .hoursOfOperation:
                    hex = 0xffFE7F00
                case .panel:
                    hex = 0xffE53935
                case .roomParty:
                    hex = 0xff424242
                case .tabletopGaming:
                    hex = 0xff00ACC1
                case .video:
                    hex = 0xffFFB300
                case .workshop:
                    hex = 0xff546E7A
                }
                
                return UIColor(hex: hex)
            }
        }
        
        public let name: String
        public let color: UIColor?
        
        public init(name: String) {
            
            self.name = name
            let categoryName = CategoryName(rawValue: name)
            color = categoryName?.color
        }
    }
    
    @NSManaged public var sessionID: String
    @NSManaged public var name: String
    @NSManaged public var sessionDescription: String?
    @NSManaged public var start: NSDate
    @NSManaged public var end: NSDate
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
    
    public var category: Category {
        get {
            return Category(name: primitiveCategory)
        }
        set {
            willChangeValueForKey(Keys.category.rawValue)
            defer {
                didChangeValueForKey(Keys.category.rawValue)
            }
            
            primitiveCategory = newValue.name
        }
    }
    @NSManaged var primitiveCategory: String
    
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
        category = Category(name: "")
        room = ""
    }
}

private extension UIColor {
    convenience init(hex: Int) {
        let red = (hex & 0xff0000) >> 16
        let green = (hex & 0xff00) >> 8
        let blue = (hex & 0xff)
        
        let rNorm = CGFloat(red) / 255
        let bNorm = CGFloat(blue) / 255
        let gNorm = CGFloat(green) / 255
        
        self.init(red: rNorm, green: gNorm, blue: bNorm, alpha: 1)
    }
}
