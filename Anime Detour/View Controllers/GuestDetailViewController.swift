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

let photoContext = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 0)

class GuestDetailViewController: UIViewController, UIScrollViewDelegate, UIWebViewDelegate, StretchingImageHeaderContainer {
    static let guestActivityGuestIDKey = (Bundle.main.bundleIdentifier ?? "") + ".guestID"
    fileprivate static let guestActivityTypeSuffix = ".guest"
    static let activityType = (Bundle.main.bundleIdentifier ?? "") + guestActivityTypeSuffix

    var guestViewModel: GuestViewModel? {
        didSet {
            if isViewLoaded {
                updateImageHeader()
            }
        }
    }
    
    var photoAspect: CGFloat = 2
    
    @IBOutlet internal weak var imageHeaderView: ImageHeaderView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var bioWebView: UIWebView!
    @IBOutlet fileprivate weak var bioWebViewHeightConstraint: NSLayoutConstraint!
    fileprivate var bioWebViewHeight: CGFloat = 400 {
        didSet {
            bioWebViewHeightConstraint.constant = bioWebViewHeight
        }
    }
    
    @IBInspectable var bioWebViewSideMargin: CGFloat = 0
    
    // MARK: Images

    lazy var imageSession: URLSession = URLSession.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateImageHeader()
        updateHeaderSize()
        
        nameLabel.text = guestViewModel?.name
        
        bioWebView.scrollView.isScrollEnabled = false
        bioWebView.loadHTMLString(guestViewModel?.bio ?? "", baseURL: nil)
        
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker
        
        let dict = GAIDictionaryBuilder.createEventDictionary(.Guest, action: .ViewDetails, label: guestViewModel?.name, value: nil)
        analytics?.send(dict)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let currentActivity: NSUserActivity
        if let activity = userActivity , activity.activityType == GuestDetailViewController.activityType {
            currentActivity = activity
        } else {
            userActivity?.invalidate()
            currentActivity = NSUserActivity(activityType: GuestDetailViewController.activityType)
            
            userActivity = currentActivity
        }
        
        currentActivity.needsSave = true
        currentActivity.becomeCurrent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userActivity?.resignCurrent()
        userActivity = nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateWebViewHeightForWidth(size.width - 2 * self.bioWebViewSideMargin)
            }, completion: nil)
        
    }
    
    // MARK: Guest Display
    
    fileprivate func updateImageHeader() {
        imageHeaderView.image = guestViewModel?.hiResPhoto(true, lowResPhotoPlaceholder: true)
        imageHeaderView.faceBounds = guestViewModel?.hiResFaceBounds
    }
    
    /**
     Update `bioWebViewHeight` by asking our `bioWebView` for the height necessary
     to display its entire contents, if it its width were set to `width`.
     */
    fileprivate func updateWebViewHeightForWidth(_ width: CGFloat) {
        guard let webView = bioWebView else {
            return
        }
        
        var frame = webView.frame
        let halfwaySize = CGSize(width: width, height: 1)
        frame.size = halfwaySize
        webView.frame = frame
        let size = webView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        
        bioWebViewHeight = size.height
    }
    
    // MARK: - NSUserActivity
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        // we don't support restoring user activity state directly
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        activity.title = guestViewModel?.name
        
        var userInfo: [String:AnyObject] = [:]
        if let viewModel = guestViewModel {
            userInfo[GuestDetailViewController.guestActivityGuestIDKey] = viewModel.guest.guestID as NSString
            activity.isEligibleForSearch = true
        } else {
            activity.isEligibleForSearch = false
        }
        
        activity.addUserInfoEntries(from: userInfo)
    }
    
    // MARK: - NSObject (KVO)
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard "hiResPhoto" == keyPath && photoContext == context else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        updateImageHeader()
    }
    
    // MARK: - Scroll view delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderImageTopConstraint(scrollView)
    }
    
    // MARK: - Web view delegate

    func webViewDidFinishLoad(_ webView: UIWebView) {
        updateWebViewHeightForWidth(webView.frame.width)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // Loading the guest's bio has a URL of about:blank.
        // Shunt other URLs to the app delegate, which will open them in the appropriate apps.
        if request.url == URL(string: "about:blank") {
            return true
        } else {
            UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
            return false
        }
    }
}
