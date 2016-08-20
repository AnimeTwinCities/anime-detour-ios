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
    static let sessionActivitySessionIDKey = (Bundle.main.bundleIdentifier ?? "") + ".sessionID"
    fileprivate static let sessionActivityTypeSuffix = ".session"
    static let activityType = (Bundle.main.bundleIdentifier ?? "") + sessionActivityTypeSuffix
    
    @IBOutlet var sessionView: SessionView!
    
    /// The aspect ratio (width / height) of the photo image view.
    @IBInspectable var photoAspect: CGFloat = 2
    
    let imagesURLSession = URLSession.shared
    
    lazy var managedObjectContext: NSManagedObjectContext! = CoreDataController.sharedInstance.managedObjectContext
    var sessionID: String! {
        didSet {
            guard let sessionID = sessionID else {
                assertionFailure("`nil` SessionID set")
                return
            }
            
            let fetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Session.Keys.sessionID.rawValue, sessionID)
            fetchRequest.fetchLimit = 1
            let results = try? managedObjectContext.fetch(fetchRequest)
            guard let session = results?.first else {
                NSLog("Received `sessionID` but couldn't find corresponding Session")
                return
            }
            
            let viewModel = SessionViewModel(session: session, managedObjectContext: managedObjectContext, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
            viewModel.delegate = self
            self.viewModel = viewModel
            
            if let sessionView = sessionView {
                sessionView.viewModel = viewModel
            }
        }
    }
    
    fileprivate var viewModel: SessionViewModel?
    
    fileprivate var shortDateFormat = "EEE – hh:mm a" // Fri – 12:30 PM
    lazy fileprivate var dateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = self.shortDateFormat
        return formatter
    }()
    lazy fileprivate var timeOnlyDateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    // MARK: - Peek Preview Action Items
    
    override var previewActionItems: [UIPreviewActionItem] {
        let changeBookmarkedAction: UIPreviewActionItem
        if viewModel?.isBookmarked ?? false {
            changeBookmarkedAction = UIPreviewAction(title: "Remove Favorite", style: UIPreviewActionStyle.default) { _, _ in
                self.toggleBookmarked()
            }
        } else {
            changeBookmarkedAction = UIPreviewAction(title: "Add Favorite", style: UIPreviewActionStyle.default) { _, _ in
                self.toggleBookmarked()
            }
        }
        
        return [changeBookmarkedAction]
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker
        let dict = GAIDictionaryBuilder.createEventDictionary(screenName, action: .ViewDetails, label: viewModel?.session.name, value: nil)
        analytics?.send(dict)

        sessionView.sessionDelegate = self
        sessionView.viewModel = viewModel
        updateHeaderSize()
        
        // Layout the sessionView immediately, so that its sizeThatFits(_) will be
        // accurate from now on based on the `viewModel` and header size.
        sessionView.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let viewSize = view.frame.size
        var preferredSize = sessionView.contentView.sizeThatFits(viewSize)
        preferredSize.width = viewSize.width
        preferredContentSize = preferredSize
        
        let currentActivity: NSUserActivity
        if let activity = userActivity , activity.activityType == SessionViewController.activityType {
            currentActivity = activity
        } else {
            userActivity?.invalidate()
            currentActivity = NSUserActivity(activityType: SessionViewController.activityType)
            
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
    
    fileprivate func toggleBookmarked() {
        do {
            try viewModel?.toggleBookmarked()
        } catch {
            NSLog("Couldn't save after toggling session bookmarked status: \((error as NSError).localizedDescription)")
            let actionString = (viewModel?.isBookmarked ?? false) ? "add favorite" : "remove favorite"
            let alert = UIAlertController(title: "Uh Oh", message: "Couldn't \(actionString). Sorry :(", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - NSUserActivity
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        sessionID = activity.userInfo?[SessionViewController.sessionActivitySessionIDKey] as? String
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        activity.title = viewModel?.name
        
        var userInfo: [AnyHashable : Any] = [:]
        if let viewModel = viewModel {
            userInfo[SessionViewController.sessionActivitySessionIDKey] = viewModel.session.sessionID
            activity.isEligibleForSearch = true
        } else {
            activity.isEligibleForSearch = false
        }
        
        activity.addUserInfoEntries(from: userInfo)
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(_ bookmarkImage: UIImage, accessibilityLabel: String) {
        sessionView.bookmarkButton.setImage(bookmarkImage, for: UIControlState())
        sessionView.bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}

extension SessionViewController: SessionViewDelegate {
    func didTapBookmarkButton() {
        toggleBookmarked()
    }
}

extension SessionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderImageTopConstraint(sessionView)
    }
}

extension SessionViewController: StretchingImageHeaderContainer {
    var imageHeaderView: ImageHeaderView! {
        return sessionView.imageHeaderView
    }
    // `photoAspect` is already a variable in the main class implmementation
}
