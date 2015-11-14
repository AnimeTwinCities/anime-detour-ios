//
//  SessionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/16/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

import AnimeDetourAPI

class SessionViewController: UIViewController, SessionViewModelDelegate {
    @IBOutlet var sessionView: SessionView!
    let imagesURLSession = NSURLSession.sharedSession()
    
    var session: Session! {
        didSet {
            if let sessionView = self.sessionView {
                let viewModel = SessionViewModel(session: self.session, imagesURLSession: self.imagesURLSession, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
                sessionView.viewModel = viewModel
            }
        }
    }
    
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

        let viewModel = SessionViewModel(session: self.session, imagesURLSession: self.imagesURLSession, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        viewModel.delegate = self
        self.sessionView.viewModel = viewModel
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String) {
        self.sessionView.bookmarkButton.setImage(bookmarkImage, forState: .Normal)
        self.sessionView.bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}