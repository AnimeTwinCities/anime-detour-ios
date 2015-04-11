//
//  InformationViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import FXForms

class InformationViewController: UITableViewController {

    // MARK: - Cell reuse identifiers

    @IBInspectable var logoIdentifier: String!
    @IBInspectable var titleIdentifier: String!
    @IBInspectable var dateIdentifier: String!
    @IBInspectable var mapLinkIdentifier: String!
    @IBInspectable var harassmentPolicyIdentifier: String!
    @IBInspectable var letterParentsIdentifier: String!
    @IBInspectable var weaponsPolicyIdentifier: String!
    @IBInspectable var websiteIdentifier: String!
    
    @IBInspectable var settingsIdentifier: String!

    // MARK: - Segue identifiers

    @IBInspectable var harassmentSegue: String!
    @IBInspectable var letterParentsSegue: String!
    @IBInspectable var weaponsPolicySegue: String!
    @IBInspectable var websiteSegue: String!
    @IBInspectable var settingsSegue: String!

    // MARK: - Table View Data Source

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
        case .Some(self.harassmentPolicyIdentifier):
            break
        case .Some(self.letterParentsIdentifier):
            break
        case .Some(self.weaponsPolicyIdentifier):
            break
        case .Some(self.websiteIdentifier):
            break
        case .Some(self.settingsIdentifier):
            break
        case let .Some(identifier):
            fatalError("Unknown reuse identifier encountered: \(identifier)")
        case .None:
            // Cells without a reuse identifier are fine
            break
        }

        return cell
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(self.harassmentSegue):
            let webVC = segue.destinationViewController as! WebViewController
            webVC.urlString = "http://www.animedetour.com/policyharrassment"
        case .Some(self.letterParentsSegue):
            let webVC = segue.destinationViewController as! WebViewController
            webVC.urlString = "http://www.animedetour.com/faqparents"
        case .Some(self.weaponsPolicySegue):
            let webVC = segue.destinationViewController as! WebViewController
            webVC.urlString = "http://www.animedetour.com/policyweapons"
        case .Some(self.websiteSegue):
            let webVC = segue.destinationViewController as! WebViewController
            webVC.urlString = "http://www.animedetour.com/"
        case .Some(self.settingsSegue):
            let acknowledgements = Acknowledgements()
            let sessionSettingsForm = SessionSettings()
            let settings = Settings(acknowledgements: acknowledgements, sessionSettingsForm: sessionSettingsForm)
            let formVC = segue.destinationViewController as! FXFormViewController
            formVC.formController.form = settings
            break
        default:
            fatalError("Unrecognized segue with identifier: \(segue.identifier)")
        }
    }

    // MARK: - Received actions

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
