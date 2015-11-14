//
//  AnalyticsViewControllers.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

extension SessionCollectionViewController: AnalyticsScreen {
    var screenName: String { return "Schedule" }
}

extension SessionTableViewController: AnalyticsScreen {
    var screenName: String {
        if self.bookmarkedOnly {
            return "Favorites"
        } else {
            return "Schedule Search"
        }
    }
}

extension SessionViewController: AnalyticsScreen {
    var screenName: String { return "Event" }
}

extension SessionFilterTableViewController: AnalyticsScreen {
    var screenName: String { return "Schedule Filter" }
}

extension GuestCollectionViewController: AnalyticsScreen {
    var screenName: String { return "Guests" }
}

extension GuestDetailTableViewController: AnalyticsScreen {
    var screenName: String { return "Guest Detail" }
}

extension MapsViewController: AnalyticsScreen {
    var screenName: String { return "Map" }
}

extension SettingsViewController: AnalyticsScreen {
    var screenName: String { return "Settings" }
}
