//
//  AnalyticsViewControllers.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

import Aspects

extension UIViewController {
    static func hookViewDidAppearForAnalytics(_ googleTracker: GAITracker) {
        let block: @convention(block) (_ info: AspectInfo, _ animated: Bool) -> Void = {
            (info: AspectInfo, animated: Bool) in
            guard let analyticsScreen = info.instance() as? AnalyticsScreen else {
                return
            }
            
            googleTracker.set(kGAIScreenName, value: analyticsScreen.screenName)
            let dict = GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject]
            googleTracker.send(dict)
        }
        // lol type-safety
        let objBlock = unsafeBitCast(block, to: AnyObject.self)
        
        do {
            try UIViewController.aspect_hook(#selector(UIViewController.viewDidAppear(_:)), with:AspectOptions(), usingBlock: objBlock)
        } catch {
            let error = error as NSError
            NSLog("Error hooking viewDidAppear: for analytics %@", error)
        }
    }
}

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

extension GuestDetailViewController: AnalyticsScreen {
    var screenName: String { return "Guest Detail" }
}

extension MapsViewController: AnalyticsScreen {
    var screenName: String { return "Map" }
}

extension SettingsViewController: AnalyticsScreen {
    var screenName: String { return "Settings" }
}
