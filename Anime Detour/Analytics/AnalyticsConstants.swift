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
        case favorite = "Favorite"
        case unfavorite = "Unfavorite"
        case notifications = "Notifications"
        case viewDetails = "View Details"
    }

    enum Category: String {
        case guest = "Guest"
        case home = "Home"
        case session = "Event"
        case settings = "Settings"
    }
}
