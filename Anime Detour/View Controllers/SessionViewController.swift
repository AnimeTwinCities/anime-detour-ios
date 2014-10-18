//
//  SessionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/16/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation
import UIKit

import ConScheduleKit

class SessionViewController: UIViewController {
    @IBOutlet var sessionView: SessionView!
    
    var session: Session! {
        didSet {
            if let sessionView = self.sessionView {
                let viewModel = SessionViewModel(session: self.session, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
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
        
        if let session = self.session {
            let viewModel = SessionViewModel(session: session, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
            self.sessionView.viewModel = viewModel
        }
    }
}