//
//  AnalyticsConstants.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/3/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

struct AnalyticsConstants {
    enum Actions: String {
        case Favorite = "Favorite"
        case Unfavorite = "Unfavorite"
        case Notifications = "Notifications"
        case ViewDetails = "View Details"
    }

    enum Category: String {
        case Guest = "Guest"
        case Home = "Home"
        case Session = "Event"
        case Settings = "Settings"
    }
}
