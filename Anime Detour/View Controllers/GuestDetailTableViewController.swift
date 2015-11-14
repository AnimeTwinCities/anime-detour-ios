//
//  GuestDetailTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestDetailTableViewController: UITableViewController, UIWebViewDelegate, GuestViewModelDelegate {
    var guestViewModel: GuestViewModel!

    private var bioWebViewHeight: CGFloat?
    private var bioWebviewLoadInitiated = false

    @IBInspectable var bioIdentifier: String!
    @IBInspectable var nameIdentifier: String!
    @IBInspectable var photoIdentifier: String!

    /// The aspect ratio (width / height) of the photo image view.
    @IBInspectable var photoAspect: CGFloat = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.guestViewModel.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let analytics = GAI.sharedInstance().defaultTracker {
            analytics.set(kGAIScreenName, value: AnalyticsConstants.Screen.GuestDetail)
            let dict = GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject]
            analytics.send(dict)
        }
    }

    private func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch cell.reuseIdentifier {
        case .Some(self.photoIdentifier):
            let imageView = cell.contentView.subviews.filter { return $0 is UIImageView }.first as! UIImageView
            imageView.image = self.guestViewModel.hiResPhoto(true, lowResPhotoPlaceholder: true)
        case .Some(self.nameIdentifier):
            cell.textLabel?.text = self.guestViewModel.name
        case .Some(self.bioIdentifier):
            let webView = cell.contentView.subviews.filter { return $0 is UIWebView }.first as! UIWebView
            webView.delegate = self
            webView.scrollView.scrollEnabled = false
            if !self.bioWebviewLoadInitiated {
                webView.loadHTMLString(self.guestViewModel.bio, baseURL: nil)
                self.bioWebviewLoadInitiated = true
            }
        default:
            fatalError("Unexpected reuse identifier: \(cell.reuseIdentifier). Expected a match against one of our xIdentifier properties.")
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        self.configure(cell, atIndexPath: indexPath)

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let row = GuestDetailTableViewCellRow(row: indexPath.row) else {
            fatalError("Unexpected row number: \(indexPath.row) in guest detail view.")
        }
        
        switch row {
        case .Photo:
            return tableView.frame.width / self.photoAspect
        case .Name:
            return 44
        case .Bio:
            return self.bioWebViewHeight ?? tableView.frame.height - 344
        }
    }

    // MARK: - Web view delegate

    func webViewDidFinishLoad(webView: UIWebView) {
        let size = webView.sizeThatFits(CGSize(width: webView.frame.width, height: CGFloat.max))

        // Calling `beginUpdates` and then `endUpdates` makes the table view reload cells,
        // getting our calculated cell height.
        self.tableView.beginUpdates()
        self.bioWebViewHeight = size.height
        self.tableView.endUpdates()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // Loading the guest's bio has a URL of about:blank.
        // Shunt other URLs to the app delegate, which will open them in the appropriate apps.
        if request.URL == NSURL(string: "about:blank") {
            return true
        } else {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
    }

    // MARK: - Guest view model delegate

    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            self.configure(cell, atIndexPath: indexPath)
        }
    }

    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError) {
        // empty
    }

}

/**
 Cases correspond to data expected to be displayed for a given row.
 */
private enum GuestDetailTableViewCellRow {
    case Photo
    case Name
    case Bio
    
    init?(row: Int) {
        switch row {
        case 0:
            self = .Photo
        case 1:
            self = .Name
        case 2:
            self = .Bio
        default:
            return nil
        }
    }
}
