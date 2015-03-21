//
//  SettingsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

import FXForms

class SettingsViewController: FXFormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let analytics = GAI.sharedInstance().defaultTracker? {
            analytics.set(kGAIScreenName, value: AnalyticsConstants.Screen.Settings)
            let dict = GAIDictionaryBuilder.createScreenView().build()
            analytics.send(dict)
        }
    }

}
