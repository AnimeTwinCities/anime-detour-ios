//
//  SessionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/16/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import AnimeDetourDataModel

class SessionViewController: UIViewController, SessionViewModelDelegate {
    static let sessionActivitySessionIDKey = (NSBundle.mainBundle().bundleIdentifier ?? "") + ".sessionID"
    private static let sessionActivityTypeSuffix = ".session"
    static let activityType = (NSBundle.mainBundle().bundleIdentifier ?? "") + sessionActivityTypeSuffix
    
    @IBOutlet var sessionView: SessionView!
    
    /// The aspect ratio (width / height) of the photo image view.
    @IBInspectable var photoAspect: CGFloat = 2
    
    let imagesURLSession = NSURLSession.sharedSession()
    
    lazy var managedObjectContext: NSManagedObjectContext! = CoreDataController.sharedInstance.managedObjectContext
    var sessionID: String! {
        didSet {
            guard let sessionID = sessionID else {
                assertionFailure("`nil` SessionID set")
                return
            }
            
            let fetchRequest = NSFetchRequest(entityName: Session.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Session.Keys.sessionID.rawValue, sessionID)
            fetchRequest.fetchLimit = 1
            let results = try? managedObjectContext.executeFetchRequest(fetchRequest)
            guard let session = results?.first as? Session else {
                NSLog("Received `sessionID` but couldn't find corresponding Session")
                return
            }
            
            let viewModel = SessionViewModel(session: session, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
            viewModel.delegate = self
            self.viewModel = viewModel
            
            if let sessionView = sessionView {
                sessionView.viewModel = viewModel
            }
        }
    }
    
    private var viewModel: SessionViewModel?
    
    private var shortDateFormat = "EEE – hh:mm a" // Fri – 12:30 PM
    lazy private var dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = self.shortDateFormat
        return formatter
    }()
    lazy private var timeOnlyDateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker
        let dict = GAIDictionaryBuilder.createEventDictionary(screenName, action: .ViewDetails, label: viewModel?.session.name, value: nil)
        analytics?.send(dict)

        sessionView.viewModel = viewModel
        updateHeaderSize()
        
        // Layout the sessionView immediately, so that its sizeThatFits(_) will be
        // accurate from now on based on the `viewModel` and header size.
        sessionView.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let viewSize = view.frame.size
        var preferredSize = sessionView.contentView.sizeThatFits(viewSize)
        preferredSize.width = viewSize.width
        preferredContentSize = preferredSize
        
        let currentActivity: NSUserActivity
        if let activity = userActivity where activity.activityType == SessionViewController.activityType {
            currentActivity = activity
        } else {
            userActivity?.invalidate()
            currentActivity = NSUserActivity(activityType: SessionViewController.activityType)
            
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
    
    // MARK: - NSUserActivity
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        sessionID = activity.userInfo?[SessionViewController.sessionActivitySessionIDKey] as? String
    }
    
    override func updateUserActivityState(activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        activity.title = viewModel?.name
        
        var userInfo: [String:AnyObject] = [:]
        if let viewModel = viewModel {
            userInfo[SessionViewController.sessionActivitySessionIDKey] = viewModel.session.sessionID
            activity.eligibleForSearch = true
        } else {
            activity.eligibleForSearch = false
        }
        
        activity.addUserInfoEntriesFromDictionary(userInfo)
    }
    
    // MARK: - Peek Preview Action Items
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        let changeBookmarkedAction: UIPreviewActionItem
        if viewModel?.isBookmarked ?? false {
            changeBookmarkedAction = UIPreviewAction(title: "Remove Favorite", style: UIPreviewActionStyle.Default) { _, _ in
                self.viewModel?.toggleBookmarked()
            }
        } else {
            changeBookmarkedAction = UIPreviewAction(title: "Add Favorite", style: UIPreviewActionStyle.Default) { _, _ in
                self.viewModel?.toggleBookmarked()
            }
        }
        
        return [changeBookmarkedAction]
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String) {
        sessionView.bookmarkButton.setImage(bookmarkImage, forState: .Normal)
        sessionView.bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}

extension SessionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderImageTopConstraint(sessionView)
    }
}

extension SessionViewController: StretchingImageHeaderContainer {
    var imageHeaderView: ImageHeaderView! {
        return sessionView.imageHeaderView
    }
    // `photoAspect` is already a variable in the main class implmementation
}
