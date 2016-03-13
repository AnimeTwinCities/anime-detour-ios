//
//  UserActivityController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/16/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

class UserActivityController: UIResponder {
    private let tabBarController: UITabBarController
    private let sessionCollectionViewController: SessionCollectionViewController?
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        let firstVC = tabBarController.viewControllers?.first as? UINavigationController
        self.sessionCollectionViewController = firstVC?.viewControllers.first as? SessionCollectionViewController
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
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
    }
}
