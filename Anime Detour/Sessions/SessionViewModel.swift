//
//  SessionViewModel.swift
//  DevFest
//
//  Created by Brendon Justin on 11/24/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

struct SessionViewModel {
    let sessionID: String
    let title: String
    let description: String?
    
    struct Category: Equatable {
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
                switch self {
                case .cosplayPhotoshoot:
                    return UIColor(red: 0xc0 / 255, green: 0xca / 255, blue: 0x33 / 255, alpha: 1)
                case .electronicGaming:
                    return UIColor(red: 0x39 / 255, green: 0x49 / 255, blue: 0xab / 255, alpha: 1)
                case .event:
                    return UIColor(red: 0x43 / 255, green: 0xa0 / 255, blue: 0x47 / 255, alpha: 1)
                case .guestSigning:
                    return UIColor(red: 0x8e / 255, green: 0x24 / 255, blue: 0xaa / 255, alpha: 1)
                case .hoursOfOperation:
                    return UIColor(red: 0xfe / 255, green: 0x7f / 255, blue: 0x00 / 255, alpha: 1)
                case .panel:
                    return UIColor(red: 0xe5 / 255, green: 0x39 / 255, blue: 0x35 / 255, alpha: 1)
                case .roomParty:
                    return UIColor(red: 0x42 / 255, green: 0x42 / 255, blue: 0x42 / 255, alpha: 1)
                case .tabletopGaming:
                    return UIColor(red: 0x00 / 255, green: 0xac / 255, blue: 0xc1 / 255, alpha: 1)
                case .video:
                    return UIColor(red: 0xff / 255, green: 0xb3 / 255, blue: 0x00 / 255, alpha: 1)
                case .workshop:
                    return UIColor(red: 0x54 / 255, green: 0x6e / 255, blue: 0x7a / 255, alpha: 1)
                }
            }
        }
        
        let name: String
        let color: UIColor?
        
        init(name: String) {
            self.name = name
            let categoryName = CategoryName(rawValue: name)
            color = categoryName?.color
        }
        
        static func ==(lhs: Category, rhs: Category) -> Bool {
            return lhs.name == rhs.name
        }
    }
    
    var color: UIColor {
        return category?.color ?? .adr_orange
    }
    
    var isStarred: Bool
    
    // Optional items
    let category: Category?
    let room: String?
    let start: Date?
    let end: Date?
    let speakerIDs: [String]
    let tags: [String]
    
    var hasEnded: Bool {
        // Assume events without a start time don't end
        guard let start = start else {
            return false
        }
        
        // assume a duration of 8 hours if we don't have an end time
        let end = self.end ?? start.addingTimeInterval(8 * 60 * 60)
        let hasEnded = Date() > end
        return hasEnded
    }
    
    func durationString(using dateFormatter: DateFormatter) -> String? {
        switch (start, end) {
        case let (start?, end?):
            let format = NSLocalizedString("%@ - %@", comment: "Time range, e.g. for session start and end")
            let stringStart = dateFormatter.string(from: start)
            let stringEnd = dateFormatter.string(from: end)
            let formatted = String(format: format, stringStart, stringEnd)
            return formatted
        case let (start?, nil):
            let format = NSLocalizedString("Starts %@", comment: "Start time, e.g. for session start")
            let stringDate = dateFormatter.string(from: start)
            let formatted = String(format: format, stringDate)
            return formatted
        case let (nil, end?):
            let format = NSLocalizedString("Ends %@", comment: "Start time, e.g. for session start")
            let stringDate = dateFormatter.string(from: end)
            let formatted = String(format: format, stringDate)
            return formatted
        case (nil, nil):
            return nil
        }
    }
}

extension SessionViewModel {
    var is18Plus: Bool {
        return tags.contains("18+")
    }
    
    var is21Plus: Bool {
        return tags.contains("21+")
    }
}
