//
//  SessionBookmarkDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/8/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

import AnimeDetourAPI

/**
Convenience collection view and table view data source.
`prepareCollectionView`/`prepareTableView` must be called before use.
*/
class SessionBookmarkDataSource: NSObject {
    let fetchedResultsController: NSFetchedResultsController
    let timeZone: NSTimeZone?
    let coreDataController: CoreDataController!
    let userDataController: UserDataController?
    var sessionCellIdentifier = "SessionCell"
    var sectionHeaderIdentifier = "SessionHeader"

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

    :param: fetchedResultsController An FRC fetching Sessions to display in a collection view.
    :param: coreDataController A controller in which Sessions may be found.
    :param: userDataController A controller for interacting with user models, e.g. bookmarked Sessions.
    */
    init(fetchedResultsController: NSFetchedResultsController, timeZone: NSTimeZone?, coreDataController: CoreDataController, userDataController: UserDataController?) {
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        self.coreDataController = coreDataController
        self.userDataController = userDataController
        super.init()
    }

    /// Prepare a collection view so the data source may supply it views.
    func prepareCollectionView(collectionView: UICollectionView) {
        // empty
    }

    /// Prepare a table view so the data source may supply it views.
    func prepareTableView(tableView: UITableView) {
        tableView.registerClass(SessionTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: self.sectionHeaderIdentifier)
    }

    func sessionBookmark(indexPath: NSIndexPath) -> SessionBookmark {
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as SessionBookmark
    }

    func session(indexPath: NSIndexPath) -> Session {
        let bookmark = self.sessionBookmark(indexPath)
        let sessionFetchRequest = NSFetchRequest(entityName: Session.entityName)
        sessionFetchRequest.predicate = NSPredicate(format: "sessionID == %@", bookmark.sessionID)
        let fetchResults = self.coreDataController.managedObjectContext.executeFetchRequest(sessionFetchRequest, error: nil)
        let session = fetchResults?.first as Session
        return session
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

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = self.fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.sessionCellIdentifier, forIndexPath: indexPath) as SessionCollectionViewCell

        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, imagesURLSession: nil, userDataController: self.userDataController, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        cell.viewModel = viewModel

        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: self.sectionHeaderIdentifier, forIndexPath: indexPath) as TextHeaderCollectionReusableView
            header.titleLabel.text = self.headerText(forSection: indexPath.section)
            return header
        default:
            assertionFailure("Unexpected supplementary view kind: \(kind)")
        }
    }

    // MARK: UITableViewDataSource

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
        let viewModel = SessionViewModel(session: session, imagesURLSession: nil, userDataController: self.userDataController, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        cell.viewModel = viewModel

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.headerText(forSection: section)
    }
}
