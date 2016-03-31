//
//  SessionCollectionViewDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import AnimeDetourDataModel

/**
Convenience collection view and table view data source.
`prepareCollectionView`/`prepareTableView` must be called before use.
*/
class SessionDataSource: NSObject, UICollectionViewDataSource, UITableViewDataSource {
    let imagesURLSession: NSURLSession?
    let fetchedResultsController: NSFetchedResultsController
    let timeZone: NSTimeZone?
    var sessionCellIdentifier = "SessionCell"
    var sectionHeaderIdentifier = "SessionHeader"
    
    weak var cellDelegate: SessionCollectionViewCellDelegate?

    private var shortDateFormat = "EEE – h:mm a" // like "Fri – 1:45 PM"
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
        formatter.dateFormat = "h:mm a" // like "1:45 PM"
        if let timeZone = self.timeZone {
            formatter.timeZone = timeZone
        }
        return formatter
    }()

    /**
    Create a data source.
    
    - parameter imagesURLSession: The NSURLSession to use for downloading images. If `nil`, images will not be downloaded.
    - parameter fetchedResultsController: An FRC fetching Sessions to display in a collection view.
    */
    init(fetchedResultsController: NSFetchedResultsController, cellDelegate: SessionCollectionViewCellDelegate?, timeZone: NSTimeZone?, imagesURLSession: NSURLSession?) {
        self.cellDelegate = cellDelegate
        self.imagesURLSession = imagesURLSession
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        super.init()
    }

    /// Prepare a collection view so the data source may supply it views.
    func prepareCollectionView(collectionView: UICollectionView) {
        // empty
    }

    /// Prepare a table view so the data source may supply it views.
    func prepareTableView(tableView: UITableView) {
        tableView.registerClass(SessionTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
    }

    func sessionAt(indexPath: NSIndexPath) -> Session {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! Session
    }

    /**
    The text to display in a section header.

    - parameter forSection: Section number. Must be a section number known to the fetched results controller.
    */
    func headerText(forSection sectionNumber: Int) -> String {
        let sectionInfo = fetchedResultsController.sections![sectionNumber] as NSFetchedResultsSectionInfo
        // If the fetched results controller has a section, it must have at least one item in it.
        // Force unwrapping it is safe.
        let start = (sectionInfo.objects!.first as! Session).start
        let name = dateFormatter.stringFromDate(start)
        return name
    }

    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(sessionCellIdentifier, forIndexPath: indexPath) as! SessionCollectionViewCell
        configure(cell, atIndexPath: indexPath)
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! TextHeaderCollectionReusableView
            header.titleLabel.text = headerText(forSection: indexPath.section)
            return header
        default:
            fatalError("Unexpected supplementary view kind: \(kind)")
        }
    }

    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(sessionCellIdentifier, forIndexPath: indexPath) as! SessionTableViewCell

        let session = sessionAt(indexPath)
        let viewModel = SessionViewModel(session: session, managedObjectContext: fetchedResultsController.managedObjectContext, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
        cell.viewModel = viewModel

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerText(forSection: section)
    }
}

extension SessionDataSource: CollectionViewFetchedResultsControllerCellCustomizer {
    func configure(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let sessionCell = cell as! SessionCollectionViewCell
        sessionCell.sessionCellDelegate = cellDelegate
        let session = sessionAt(indexPath)
        let viewModel = SessionViewModel(session: session, managedObjectContext: fetchedResultsController.managedObjectContext, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
        sessionCell.viewModel = viewModel
    }
}
