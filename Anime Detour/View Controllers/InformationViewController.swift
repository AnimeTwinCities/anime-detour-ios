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
    
    fileprivate var afterTransitionSize: CGSize?
    
    // MARK: - View Controller
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        afterTransitionSize = size
        coordinator.animate(alongsideTransition: { _ in
            let tableView = self.tableView
            let indexPath = IndexPath(row: 0, section: 0)
            tableView?.beginUpdates()
            if let cell = tableView?.cellForRow(at: indexPath) {
                self.configure(cell, forRowAtIndexPath: indexPath)
            }
            tableView?.endUpdates()
        }, completion: nil)
    }

    fileprivate func configure(_ cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        
        switch cell.reuseIdentifier {
        case logoIdentifier?:
            if let imageView = cell.contentView.subviews.filter({
                return $0.isKind(of: UIImageView.self)
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
                    if horizontalSizeClass == .regular {
                        image = UIImage(named: "ADHeader1152")!
                    } else {
                        image = UIImage(named: "AD-Header-Logo-375")!
                    }
                }
                
                imageView.image = image
            }
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
        case .none:
            // Cells without a reuse identifier are fine
            break
        }
    }
    
    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        configure(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let url: URL
        switch (cell.reuseIdentifier) {
        case harassmentPolicyIdentifier?:
            url = URL(string: "http://www.animedetour.com/policyharrassment")!
        case letterParentsIdentifier?:
            url = URL(string: "http://www.animedetour.com/faqparents")!
        case weaponsPolicyIdentifier?:
            url = URL(string: "http://www.animedetour.com/policyweapons")!
        case websiteIdentifier?:
            url = URL(string: "http://www.animedetour.com/")!
        default:
            return
        }
        
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier) {
        case settingsSegue?:
            let acknowledgements = Acknowledgements()
            let sessionSettingsForm = SessionSettings()
            let settings = Settings(acknowledgements: acknowledgements, sessionSettingsForm: sessionSettingsForm)
            let formVC = segue.destination as! FXFormViewController
            formVC.formController.form = settings
            break
        default:
            fatalError("Unrecognized segue with identifier: \(segue.identifier)")
        }
    }

    // MARK: - Received actions

    @IBAction func showVenueOnMap(_ sender: AnyObject?) {
        let query = "DoubleTree by Hilton, Bloomington, MN".addingPercentEncoding(withAllowedCharacters: CharacterSet())!
        let googleMapsInstalled = UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)

        if googleMapsInstalled {
            // Google maps installed
        } else {
            // use Apple maps
        }

        let urlString = "http://maps.apple.com/?q=\(query)"
        UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
    }
}

class MapLinkCell: UITableViewCell {
    @IBOutlet var linkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let title = linkButton.title(for: .normal)!
        
        let font: UIFont = (linkButton.titleLabel?.font)!
        let fontHeight = font.capHeight + abs(font.descender)
        
        let markerImage = #imageLiteral(resourceName: "map_marker")
        let imageHeight = 20 as CGFloat
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = markerImage
        iconAttachment.bounds = CGRect(x: -3, y: (fontHeight - imageHeight) / 2, width: imageHeight, height: imageHeight)
        
        let iconString = NSAttributedString(attachment: iconAttachment)
        let textString = NSAttributedString(string: " " + title)
        
        // Need a space before the image attachment for the image to use the tint color
        let attributedLink = NSMutableAttributedString(string: " ")
        attributedLink.append(iconString)
        attributedLink.append(textString)
        
        linkButton.setAttributedTitle(attributedLink, for: .normal)
    }
}
