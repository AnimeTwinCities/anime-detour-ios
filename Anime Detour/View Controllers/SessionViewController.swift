//
//  SessionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/16/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

import AnimeDetourDataModel

class SessionViewController: UIViewController, SessionViewModelDelegate {
    @IBOutlet var sessionView: SessionView!
    
    /// The aspect ratio (width / height) of the photo image view.
    @IBInspectable var photoAspect: CGFloat = 2
    
    let imagesURLSession = NSURLSession.sharedSession()
    
    var session: Session! {
        didSet {
            let viewModel = SessionViewModel(session: session, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
            viewModel.delegate = self
            self.viewModel = viewModel
            
            if let sessionView = sessionView {
                sessionView.viewModel = viewModel
            }
        }
    }
    
    private var viewModel: SessionViewModel?
    
    private var shortDateFormat = "MM/dd hh:mm a"
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

        sessionView.viewModel = viewModel
        updateHeaderSize()
    }
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        let changeBookmarkedAction: UIPreviewActionItem
        if session.bookmarked {
            changeBookmarkedAction = UIPreviewAction(title: "Remove Bookmark", style: UIPreviewActionStyle.Default) { _, _ in
                self.viewModel?.toggleBookmarked()
            }
        } else {
            changeBookmarkedAction = UIPreviewAction(title: "Bookmark", style: UIPreviewActionStyle.Default) { _, _ in
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
