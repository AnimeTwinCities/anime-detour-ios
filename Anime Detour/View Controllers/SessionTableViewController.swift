//
//  FavoriteSessionsTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import Foundation
import UIKit

import AnimeDetourDataModel

class SessionTableViewController: UITableViewController, UISearchResultsUpdating {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy var coreDataController = CoreDataController.sharedInstance

    @IBInspectable var bookmarkedOnly: Bool = false {
        didSet {
            if !bookmarkedOnly {
                title = "Search"
            }
        }
    }

    @IBOutlet var defaultRightBarButtonItem: UIBarButtonItem?

    // MARK: Fetch Predicate

    var searchPredicate: NSPredicate? {
        didSet {
            if let frc = fetchedResultsController {
                let request = frc.fetchRequest
                request.predicate = completePredicate

                do {
                    try frc.performFetch()
                } catch {
                    let error = error as NSError
                    assertionFailure("Error performing search fetch in session table: \(error)")
                }

                tableView.reloadData()
            }
        }
    }

    var completePredicate: NSPredicate? {
        var predicates: [NSPredicate] = []
        if bookmarkedOnly {
            let bookmarkPredicate = NSPredicate(format: "%K == YES", Session.Keys.bookmarked.rawValue)
            predicates.append(bookmarkPredicate)
        }

        if let searchPredicate = searchPredicate {
            predicates.append(searchPredicate)
        }
        
        guard predicates.count > 0 else {
            return nil
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return compound
    }

    // MARK: Core Data

    private var managedObjectContext: NSManagedObjectContext { return coreDataController.managedObjectContext }

    /// Fetched results controller over `Session`s.
    private var fetchedResultsController: NSFetchedResultsController?

    lazy private var fetchedResultsControllerDelegate: TableViewFetchedResultsControllerDelegate = {
        let delegate = TableViewFetchedResultsControllerDelegate()
        delegate.tableView = self.tableView
        return delegate
    }()

    /**
    Fetch request for all SessionBookmarks, sorted by the `Session`'s ID. Creates a new fetch request on every access.
    */
    private var sessionsFetchRequest: NSFetchRequest {
        get {
            let predicate = completePredicate
            let sortDescriptors = [NSSortDescriptor(key: Session.Keys.startTime.rawValue, ascending: true), NSSortDescriptor(key: Session.Keys.name.rawValue, ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: Session.entityName)
            sessionsFetchRequest.predicate = predicate
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }

    // MARK: Search

    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.searchBar.placeholder = "Search Sessions"

        return controller
    }()

    private var lastSearchText: String?

    // MARK: Table view

    /**
    Table view data source that we call through to from our data
    source methods.
    */
    lazy private var dataSource: SessionDataSource! = SessionDataSource(fetchedResultsController: self.fetchedResultsController!, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession)

    private var timeZone: NSTimeZone = NSTimeZone(name: "America/Chicago")! // hard-coded for Anime-Detour

    private var selectedCellIndex: NSIndexPath?
    
    // MARK: Segue identifiers

    @IBInspectable var detailIdentifier: String!

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let frc = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        frc.delegate = fetchedResultsControllerDelegate
        fetchedResultsController = frc

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        dataSource.prepareTableView(tableView)

        do {
            try frc.performFetch()
        } catch {
            let error = error as NSError
            NSLog("Error fetching sessions in session table: %@", error)
        }

        navigationItem.rightBarButtonItem = defaultRightBarButtonItem

        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.text = lastSearchText
    }

    // MARK: - Table View Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.numberOfSectionsInTableView(tableView)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    // MARK: - Search Results Updating

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard searchController.active else {
            return
        }
        
        let searchText = searchController.searchBar.text
        lastSearchText = searchText

        var searchPredicate: NSPredicate?
        defer {
            self.searchPredicate = searchPredicate
        }
        
        if case let searchText? = searchText where searchText.characters.count > 0 {
            // Case- and diacritic-insensitive searching
            searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        }
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch(identifier) {
        case detailIdentifier:
            // Get the selected index path
            let cell = sender as! UITableViewCell
            selectedCellIndex = tableView.indexPathForCell(cell)

            // Block the detail segue while in editing mode
            return !tableView.editing
        default:
            // Always allow other segues
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        searchController.active = false
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker

        switch (segue.identifier) {
        case detailIdentifier?:
            let detailVC = segue.destinationViewController as! SessionViewController
            let selectedIndexPath = selectedCellIndex!
            let selectedSession = dataSource.sessionAt(selectedIndexPath)
            detailVC.sessionID = selectedSession.sessionID

            let dict = GAIDictionaryBuilder.createEventDictionary(.Session, action: .ViewDetails, label: selectedSession.name, value: nil)
            analytics?.send(dict)
        default:
            // Segues we don't know about are fine.
            break
        }
    }
}
