//
//  GuestDetailTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

import AnimeDetourDataModel
import CoreData

let photoContext = UnsafeMutablePointer<Void>.alloc(1)

class GuestDetailTableViewController: UITableViewController, UIWebViewDelegate, StretchingImageHeaderContainer {
    static let guestActivityGuestIDKey = (NSBundle.mainBundle().bundleIdentifier ?? "") + ".guestID"
    private static let guestActivityTypeSuffix = ".guest"
    static let activityType = (NSBundle.mainBundle().bundleIdentifier ?? "") + guestActivityTypeSuffix

    var guestViewModel: GuestViewModel? {
        didSet {
            if isViewLoaded() {
                updateImageHeader()
                tableView?.reloadData()
            }
        }
    }
    
    var imageHeaderView: ImageHeaderView!
    var photoAspect: CGFloat = 2
    
    private weak var bioWebView: UIWebView?
    private var bioWebViewHeight: CGFloat?
    private var bioWebviewLoadInitiated = false
    
    @IBInspectable var bioWebViewSideMargin: CGFloat = 0
    @IBInspectable var bioIdentifier: String!
    @IBInspectable var nameIdentifier: String!
    
    // MARK: Images

    lazy var imageSession: NSURLSession = NSURLSession.sharedSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateImageHeader()
        updateHeaderSize()
        
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker
        
        let dict = GAIDictionaryBuilder.createEventDictionary(.Guest, action: .ViewDetails, label: guestViewModel?.name, value: nil)
        analytics?.send(dict)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let currentActivity: NSUserActivity
        if let activity = userActivity where activity.activityType == GuestDetailTableViewController.activityType {
            currentActivity = activity
        } else {
            userActivity?.invalidate()
            currentActivity = NSUserActivity(activityType: GuestDetailTableViewController.activityType)
            
            userActivity = currentActivity
        }
        
        currentActivity.needsSave = true
        currentActivity.becomeCurrent()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        userActivity?.resignCurrent()
        userActivity = nil
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updateWebViewHeightForWidth(size.width - 2 * bioWebViewSideMargin)
    }
    
    // MARK: Guest Display
    
    private func updateImageHeader() {
        imageHeaderView = tableView.tableHeaderView as! ImageHeaderView
        imageHeaderView.image = guestViewModel?.hiResPhoto(true, lowResPhotoPlaceholder: true)
        imageHeaderView.faceBounds = guestViewModel?.hiResFaceBounds
    }
    
    /**
     Update `bioWebViewHeight` by asking our `bioWebView` for the height necessary
     to display its entire contents, if it its width were set to `width`.
     */
    private func updateWebViewHeightForWidth(width: CGFloat) {
        guard let webView = bioWebView else {
            return
        }
        
        var frame = webView.frame
        let halfwaySize = CGSize(width: width, height: 1)
        frame.size = halfwaySize
        webView.frame = frame
        let size = webView.sizeThatFits(CGSize(width: width, height: CGFloat.max))
        
        // Calling `beginUpdates` and then `endUpdates` makes the table view reload cells,
        // getting our calculated cell height.
        tableView.beginUpdates()
        bioWebViewHeight = size.height
        tableView.endUpdates()
    }

    private func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch cell.reuseIdentifier {
        case nameIdentifier?:
            (cell as! GuestNameCell).nameLabel.text = guestViewModel?.name
        case bioIdentifier?:
            let webView = cell.contentView.subviews.flatMap { $0 as? UIWebView }.first!
            bioWebView = webView
            webView.delegate = self
            webView.scrollView.scrollEnabled = false
            if !bioWebviewLoadInitiated {
                webView.loadHTMLString(guestViewModel?.bio ?? "", baseURL: nil)
                bioWebviewLoadInitiated = true
            }
        case let identifier:
            fatalError("Unexpected reuse identifier: \(identifier). Expected a match against one of our xIdentifier properties.")
        }
    }
    
    // MARK: - NSUserActivity
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        // we don't support restoring user activity state directly
    }
    
    override func updateUserActivityState(activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        activity.title = guestViewModel?.name
        
        var userInfo: [String:AnyObject] = [:]
        if let viewModel = guestViewModel {
            userInfo[GuestDetailTableViewController.guestActivityGuestIDKey] = viewModel.guest.guestID
            activity.eligibleForSearch = true
        } else {
            activity.eligibleForSearch = false
        }
        
        activity.addUserInfoEntriesFromDictionary(userInfo)
    }
    
    // MARK: - NSObject (KVO)
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard "hiResPhoto" == keyPath && photoContext == context else {
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
        updateImageHeader()
    }
    
    // MARK: - Scroll view delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderImageTopConstraint(tableView)
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        configure(cell, atIndexPath: indexPath)

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let row = GuestDetailTableViewCellRow(row: indexPath.row) else {
            fatalError("Unexpected row number: \(indexPath.row) in guest detail view.")
        }
        
        switch row {
        case .Name:
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        case .Bio:
            return bioWebViewHeight ?? tableView.frame.height - 344
        }
    }

    // MARK: - Web view delegate

    func webViewDidFinishLoad(webView: UIWebView) {
        updateWebViewHeightForWidth(webView.frame.width)
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
}

class GuestNameCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
}

/**
 Cases correspond to data expected to be displayed for a given row.
 */
private enum GuestDetailTableViewCellRow {
    case Name
    case Bio
    
    init?(row: Int) {
        switch row {
        case 0:
            self = .Name
        case 1:
            self = .Bio
        default:
            return nil
        }
    }
}
