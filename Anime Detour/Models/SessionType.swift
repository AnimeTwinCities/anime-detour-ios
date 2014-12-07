//
//  ProgrammingType.swift
//  Anime Detour
//
//  Created by Brendon Justin on 12/7/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import UIKit

enum SessionType {
    case Gaming
    case GuestRelations
    case Photoshoot
    case Programming
    case RoomParties
    case Video

    var color: UIColor {
        switch self {
        case Gaming:
            // #fbff96
            return UIColor(red: 251 / 255, green: 255 / 255, blue: 150 / 255, alpha: 1)
        case GuestRelations:
            // #b6caff
            return UIColor(red: 182 / 255, green: 202 / 255, blue: 255 / 255, alpha: 1)
        case Photoshoot:
            // #00fec8
            return UIColor(red: 0 / 255, green: 254 / 255, blue: 200 / 255, alpha: 1)
        case Programming:
            // #ffab36
            return UIColor(red: 255 / 255, green: 171 / 255, blue: 54 / 255, alpha: 1)
        case RoomParties:
            // #fac0fe
            return UIColor(red: 250 / 255, green: 192 / 255, blue: 254 / 255, alpha: 1)
        case Video:
            // #ffab36
            return UIColor(red: 95 / 255, green: 251 / 255, blue: 86 / 255, alpha: 1)
        }
    }

    /**
    Find a SessionType by name.
    
    :param: name The name of the session type. Case-insensitive.
    */
    static func from(name: String) -> SessionType? {
        switch name.lowercaseString {
        case "gaming":
            return Gaming
        case "guest relations":
            return GuestRelations
        case "photoshoot":
            return Photoshoot
        case "programming":
            return Programming
        case "room parties":
            return RoomParties
        case "video":
            return Video
        default:
            return nil
        }
    }
}