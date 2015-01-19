//
//  SessionCollectionViewDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import ConScheduleKit

class SessionTableViewDataSource: NSObject, UITableViewDataSource {
    let imagesURLSession: NSURLSession?
    let fetchedResultsController: NSFetchedResultsController
    let timeZone: NSTimeZone?
    let userDataController: UserDataController?
    var sessionCellIdentifier = "SessionCell"
    var sectionHeaderIdentifier = "SessionSectionHeader"

    private var shortDateFormat = "EEEE – hh:mm a" // like "Friday – 12:45 PM"
    lazy private var dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = self.shortDateFormat
        if let timeZone = self.timeZone {
            formatter.timeZone = timeZone
        }
        return formatter
    }()
    lazy private var timeOnlyDateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "hh:mm a"
        if let timeZone = self.timeZone {
            formatter.timeZone = timeZone
        }
        return formatter
    }()

    /**
    Create a data source.
    
    :param: imagesURLSession The NSURLSession to use for downloading images. If `nil`, images will not be downloaded.
    :param: fetchedResultsController An FRC fetching Sessions to display in a collection view.
    :param: userDataController A controller for interacting with user models, e.g. bookmarked Sessions.
    */
    init(fetchedResultsController: NSFetchedResultsController, timeZone: NSTimeZone?, imagesURLSession: NSURLSession?, userDataController: UserDataController?) {
        self.imagesURLSession = imagesURLSession
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        self.userDataController = userDataController
        super.init()
    }

    /// Prepare a table view so the data source may supply it views.
    func prepareTableView(tableView: UITableView) {
        tableView.registerClass(SessionTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: self.sectionHeaderIdentifier)
    }
    
    func session(indexPath: NSIndexPath) -> Session {
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as Session
    }

    /**
    The text to display in a section header.

    :param: forSection Section number. Must be a section number known to the fetched results controller.
    */
    func headerText(forSection sectionNumber: Int) -> String {
        let sectionInfo = self.fetchedResultsController.sections![sectionNumber] as NSFetchedResultsSectionInfo
        // If the fetched results controller has a section, it must have at least one item in it.
        // Force unwrapping it is safe.
        let start = (sectionInfo.objects as [Session]).first!.start
        let name = self.dateFormatter.stringFromDate(start)
        return name
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = self.fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.sessionCellIdentifier, forIndexPath: indexPath) as SessionTableViewCell
        
        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        cell.viewModel = viewModel
        
        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.headerText(forSection: section)
    }
}