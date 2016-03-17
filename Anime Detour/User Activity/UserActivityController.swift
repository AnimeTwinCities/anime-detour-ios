//
//  UserActivityController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/16/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

let ActivityTypeKey = (NSBundle.mainBundle().bundleIdentifier ?? "") + ".activityType"

class UserActivityController: UIResponder {
    private let tabBarController: UITabBarController
    private let guestCollectionViewController: GuestCollectionViewController?
    private let sessionCollectionViewController: SessionCollectionViewController?
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        let firstVC = tabBarController.viewControllers?.first as? UINavigationController
        let secondVC = tabBarController.viewControllers?[2] as? UINavigationController
        self.guestCollectionViewController = secondVC?.viewControllers.first as? GuestCollectionViewController
        self.sessionCollectionViewController = firstVC?.viewControllers.first as? SessionCollectionViewController
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        switch KnownActivityTypes(activityType: activity.activityType) {
        case .Guest?:
            guard let guestCollectionViewController = self.guestCollectionViewController else {
                return
            }
            
            let navController = guestCollectionViewController.navigationController!
            
            guard let tabIndex = tabBarController.viewControllers?.indexOf(navController) else {
                return
            }
            
            tabBarController.selectedIndex = tabIndex
            guestCollectionViewController.navigationController?.popToViewController(guestCollectionViewController, animated: false)
            guestCollectionViewController.restoreUserActivityState(activity)
        case .Session?:
            guard let sessionCollectionViewController = self.sessionCollectionViewController else {
                return
            }
            
            let navController = sessionCollectionViewController.navigationController!
            
            guard let tabIndex = tabBarController.viewControllers?.indexOf(navController) else {
                return
            }
            
            tabBarController.selectedIndex = tabIndex
            sessionCollectionViewController.navigationController?.popToViewController(sessionCollectionViewController, animated: false)
            sessionCollectionViewController.restoreUserActivityState(activity)
        default:
            return
        }
        
    }
}

private enum KnownActivityTypes {
    case Guest
    case Session
    
    init?(activityType: String) {
        switch activityType {
        case GuestDetailTableViewController.activityType:
            self = .Guest
        case SessionViewController.activityType:
            self = .Session
        default:
            return nil
        }
    }
}
