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
    let imagesURLSession: URLSession?
    let fetchedResultsController: NSFetchedResultsController<Session>
    let timeZone: TimeZone?
    var sessionCellIdentifier = "SessionCell"
    var sectionHeaderIdentifier = "SessionHeader"
    
    weak var cellDelegate: SessionCollectionViewCellDelegate?

    fileprivate var shortDateFormat = "EEE – h:mm a" // like "Fri – 1:45 PM"
    lazy fileprivate var dateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = self.shortDateFormat
        if let timeZone = self.timeZone {
            formatter.timeZone = timeZone as TimeZone!
        }
        return formatter
    }()
    lazy fileprivate var timeOnlyDateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // like "1:45 PM"
        if let timeZone = self.timeZone {
            formatter.timeZone = timeZone as TimeZone!
        }
        return formatter
    }()

    /**
    Create a data source.
    
    - parameter imagesURLSession: The NSURLSession to use for downloading images. If `nil`, images will not be downloaded.
    - parameter fetchedResultsController: An FRC fetching Sessions to display in a collection view.
    */
    init(fetchedResultsController: NSFetchedResultsController<Session>, cellDelegate: SessionCollectionViewCellDelegate?, timeZone: TimeZone?, imagesURLSession: URLSession?) {
        self.cellDelegate = cellDelegate
        self.imagesURLSession = imagesURLSession
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        super.init()
    }

    /// Prepare a collection view so the data source may supply it views.
    func prepareCollectionView(_ collectionView: UICollectionView) {
        // empty
    }

    /// Prepare a table view so the data source may supply it views.
    func prepareTableView(_ tableView: UITableView) {
        tableView.register(SessionTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
    }

    func sessionAt(_ indexPath: IndexPath) -> Session {
        return fetchedResultsController.object(at: indexPath)
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
        let name = dateFormatter.string(from: start)
        return name
    }

    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sessionCellIdentifier, for: indexPath) as! SessionCollectionViewCell
        configure(cell, atIndexPath: indexPath)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionHeaderIdentifier, for: indexPath) as! TextHeaderCollectionReusableView
            header.titleLabel.text = headerText(forSection: (indexPath as NSIndexPath).section)
            return header
        default:
            fatalError("Unexpected supplementary view kind: \(kind)")
        }
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: sessionCellIdentifier, for: indexPath) as! SessionTableViewCell

        let session = sessionAt(indexPath)
        let viewModel = SessionViewModel(session: session, managedObjectContext: fetchedResultsController.managedObjectContext, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
        cell.viewModel = viewModel

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerText(forSection: section)
    }
}

extension SessionDataSource: CollectionViewFetchedResultsControllerCellCustomizer {
    func configure(_ cell: UICollectionViewCell, atIndexPath indexPath: IndexPath) {
        let sessionCell = cell as! SessionCollectionViewCell
        sessionCell.sessionCellDelegate = cellDelegate
        let session = sessionAt(indexPath)
        let viewModel = SessionViewModel(session: session, managedObjectContext: fetchedResultsController.managedObjectContext, imagesURLSession: imagesURLSession, sessionStartTimeFormatter: dateFormatter, shortTimeFormatter: timeOnlyDateFormatter)
        sessionCell.viewModel = viewModel
    }
}
