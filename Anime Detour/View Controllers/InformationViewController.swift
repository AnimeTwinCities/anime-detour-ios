//
//  InformationViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class InformationViewController: UITableViewController {

    @IBInspectable var logoIdentifier: String!
    @IBInspectable var titleIdentifier: String!
    @IBInspectable var dateIdentifier: String!
    @IBInspectable var mapLinkIdentifier: String!
    @IBInspectable var weaponsPolicyIdentifier: String!

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)

        switch cell.reuseIdentifier {
        case .Some(self.logoIdentifier):
            let horizontalSizeClass = self.traitCollection.horizontalSizeClass
            if let imageView = cell.contentView.subviews.filter({
                return $0.isKindOfClass(UIImageView.self)
            }).first as? UIImageView {
                if horizontalSizeClass == .Regular {
                    imageView.image = UIImage(named: "ADHeader1152")
                } else {
                    imageView.image = UIImage(named: "AD-Header-Logo-375")
                }
            }
            break
        case .Some(self.titleIdentifier):
            break
        case .Some(self.dateIdentifier):
            break
        case .Some(self.mapLinkIdentifier):
            break
        case .Some(self.weaponsPolicyIdentifier):
            break
        case let .Some(identifier):
            fatalError("Unknown reuse identifier encountered: \(identifier)")
        case .None:
            // Cells without a reuse identifier are fine
            break
        }

        return cell
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
