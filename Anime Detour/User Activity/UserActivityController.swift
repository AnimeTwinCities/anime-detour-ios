//
//  UserActivityController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/16/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

let ActivityTypeKey = (Bundle.main.bundleIdentifier ?? "") + ".activityType"

class UserActivityController: UIResponder {
    fileprivate let tabBarController: UITabBarController
    fileprivate let guestCollectionViewController: GuestCollectionViewController?
    fileprivate let sessionCollectionViewController: SessionCollectionViewController?
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        let firstVC = tabBarController.viewControllers?.first as? UINavigationController
        let secondVC = tabBarController.viewControllers?[2] as? UINavigationController
        self.guestCollectionViewController = secondVC?.viewControllers.first as? GuestCollectionViewController
        self.sessionCollectionViewController = firstVC?.viewControllers.first as? SessionCollectionViewController
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        switch KnownActivityTypes(activityType: activity.activityType) {
        case .guest?:
            guard let guestCollectionViewController = self.guestCollectionViewController else {
                return
            }
            
            let navController = guestCollectionViewController.navigationController!
            
            guard let tabIndex = tabBarController.viewControllers?.index(of: navController) else {
                return
            }
            
            tabBarController.selectedIndex = tabIndex
            _ = guestCollectionViewController.navigationController?.popToViewController(guestCollectionViewController, animated: false)
            guestCollectionViewController.restoreUserActivityState(activity)
        case .session?:
            guard let sessionCollectionViewController = self.sessionCollectionViewController else {
                return
            }
            
            let navController = sessionCollectionViewController.navigationController!
            
            guard let tabIndex = tabBarController.viewControllers?.index(of: navController) else {
                return
            }
            
            tabBarController.selectedIndex = tabIndex
            _ = sessionCollectionViewController.navigationController?.popToViewController(sessionCollectionViewController, animated: false)
            sessionCollectionViewController.restoreUserActivityState(activity)
        default:
            return
        }
        
    }
}

private enum KnownActivityTypes {
    case guest
    case session
    
    init?(activityType: String) {
        switch activityType {
        case GuestDetailViewController.activityType:
            self = .guest
        case SessionViewController.activityType:
            self = .session
        default:
            return nil
        }
    }
}
