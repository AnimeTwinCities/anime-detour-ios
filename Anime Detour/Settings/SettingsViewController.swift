//
//  SettingsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 4/1/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import FXForms

class SettingsViewController: FXFormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        title = NSLocalizedString("Settings", comment: "Settings view controller title")
    }
    
    @objc fileprivate func showSettings() {
        let application = UIApplication.shared
        application.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
    }
}
