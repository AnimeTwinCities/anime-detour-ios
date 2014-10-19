//
//  InformationViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

class InformationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func showVenueOnMap(sender: AnyObject?) {
        let query = ("DoubleTree by Hilton, Bloomington, MN" as NSString).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let googleMapsInstalled = UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)

        if googleMapsInstalled {
            // Google maps installed
        } else {
            // use Apple maps
        }

        let urlString = "http://maps.apple.com/?q=\(query)"
        UIApplication.sharedApplication().openURL(NSURL(string: urlString)!)
    }
}
