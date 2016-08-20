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

open class Session: NSManagedObject {
    open static let entityName: String = "Session"
    
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
        fileprivate enum CategoryName: String {
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
                    hex = 0xC0CA33
                case .electronicGaming:
                    hex = 0x3949AB
                case .event:
                    hex = 0x43A047
                case .guestSigning:
                    hex = 0x8E24AA
                case .hoursOfOperation:
                    hex = 0xFE7F00
                case .panel:
                    hex = 0xE53935
                case .roomParty:
                    hex = 0x424242
                case .tabletopGaming:
                    hex = 0x00ACC1
                case .video:
                    hex = 0xFFB300
                case .workshop:
                    hex = 0x546E7A
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
    
    @NSManaged open var sessionID: String
    @NSManaged open var name: String
    @NSManaged open var sessionDescription: String?
    @NSManaged open var start: Date
    @NSManaged open var end: Date
    @NSManaged open var room: String
    @NSManaged open var bookmarked: Bool
    
    open var bannerURL: URL? {
        get {
            willAccessValue(forKey: Keys.bannerURL.rawValue)
            defer {
                didAccessValue(forKey: Keys.bannerURL.rawValue)
            }
            
            return primitiveBannerURL.flatMap { URL(string: $0) }
        }
        set {
            willChangeValue(forKey: Keys.bannerURL.rawValue)
            defer {
                didChangeValue(forKey: Keys.bannerURL.rawValue)
            }
            
            primitiveBannerURL = newValue?.absoluteString
        }
    }
    @NSManaged var primitiveBannerURL: String?
    
    open var category: Category {
        get {
            return Category(name: primitiveCategory)
        }
        set {
            willChangeValue(forKey: Keys.category.rawValue)
            defer {
                didChangeValue(forKey: Keys.category.rawValue)
            }
            
            primitiveCategory = newValue.name
        }
    }
    @NSManaged var primitiveCategory: String
    
    open var hosts: [String] {
        get {
            willAccessValue(forKey: Keys.hosts.rawValue)
            defer {
                didAccessValue(forKey: Keys.hosts.rawValue)
            }
            return primitiveHosts.components(separatedBy: "SPLIT, ")
        }
        set {
            willChangeValue(forKey: Keys.hosts.rawValue)
            defer {
                didChangeValue(forKey: Keys.hosts.rawValue)
            }
            
            primitiveHosts = newValue.joined(separator: "SPLIT, ")
        }
    }
    @NSManaged var primitiveHosts: String
    
    open var tags: [String] {
        get {
            willAccessValue(forKey: Keys.tags.rawValue)
            defer {
                didAccessValue(forKey: Keys.tags.rawValue)
            }
            return primitiveTags.components(separatedBy: "SPLIT, ")
        }
        set {
            willChangeValue(forKey: Keys.tags.rawValue)
            defer {
                didChangeValue(forKey: Keys.tags.rawValue)
            }
            primitiveTags = newValue.joined(separator: "SPLIT, ")
        }
    }
    @NSManaged var primitiveTags: String
    
    override open var description: String {
        return "Session: \(name) - \(sessionDescription)"
    }

    open override func awakeFromInsert() {
        super.awakeFromInsert()

        // set empty default strings for String properties
        sessionID = ""
        name = ""
        category = Category(name: "")
        room = ""
    }
}

extension Session.Category: Equatable {
    // empty
}

public func ==(categoryOne: Session.Category, categoryTwo: Session.Category) -> Bool {
    return (categoryOne.name == categoryTwo.name) && (categoryOne.color == categoryTwo.color)
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
