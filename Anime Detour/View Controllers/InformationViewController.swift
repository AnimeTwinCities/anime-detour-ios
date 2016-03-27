//
//  InformationViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import SafariServices

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

    @IBInspectable var settingsSegue: String!
    
    // MARK: Logo Image
    
    private var afterTransitionSize: CGSize?
    
    // MARK: - View Controller
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        afterTransitionSize = size
        coordinator.animateAlongsideTransition({ _ in
            let tableView = self.tableView
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            tableView.beginUpdates()
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                self.configure(cell, forRowAtIndexPath: indexPath)
            }
            tableView.endUpdates()
        }, completion: nil)
    }

    private func configure(cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        switch cell.reuseIdentifier {
        case logoIdentifier?:
            if let imageView = cell.contentView.subviews.filter({
                return $0.isKindOfClass(UIImageView.self)
            }).first as? UIImageView {
                let image: UIImage
                if let size = afterTransitionSize {
                    switch Int(size.width) {
                    case 0..<415: // Portrait on known iphones
                        image = UIImage(named: "AD-Header-Logo-375")!
                    case 415..<Int.max: // Landscape
                        image = UIImage(named: "ADHeader1152")!
                    default:
                        image = UIImage(named: "ADHeader1152")!
                    }
                } else {
                    let horizontalSizeClass = traitCollection.horizontalSizeClass
                    if horizontalSizeClass == .Regular {
                        image = UIImage(named: "ADHeader1152")!
                    } else {
                        image = UIImage(named: "AD-Header-Logo-375")!
                    }
                }
                
                imageView.image = image
            }
            break
        case titleIdentifier?:
            break
        case dateIdentifier?:
            break
        case mapLinkIdentifier?:
            break
        case harassmentPolicyIdentifier?:
            break
        case letterParentsIdentifier?:
            break
        case weaponsPolicyIdentifier?:
            break
        case websiteIdentifier?:
            break
        case settingsIdentifier?:
            break
        case let identifier?:
            fatalError("Unknown reuse identifier encountered: \(identifier)")
        case .None:
            // Cells without a reuse identifier are fine
            break
        }
    }
    
    // MARK: - Table View Data Source

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        configure(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        
        let url: NSURL
        switch (cell.reuseIdentifier) {
        case harassmentPolicyIdentifier?:
            url = NSURL(string: "http://www.animedetour.com/policyharrassment")!
        case letterParentsIdentifier?:
            url = NSURL(string: "http://www.animedetour.com/faqparents")!
        case weaponsPolicyIdentifier?:
            url = NSURL(string: "http://www.animedetour.com/policyweapons")!
        case websiteIdentifier?:
            url = NSURL(string: "http://www.animedetour.com/")!
        default:
            return
        }
        
        let safari = SFSafariViewController(URL: url)
        presentViewController(safari, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case settingsSegue?:
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
        let query = "DoubleTree by Hilton, Bloomington, MN".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet())!
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
