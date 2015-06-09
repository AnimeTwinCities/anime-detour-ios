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

import AnimeDetourAPI

class SessionTableViewController: UITableViewController, UISearchResultsUpdating {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy var coreDataController = CoreDataController.sharedInstance

    @IBInspectable var bookmarkedOnly: Bool = false {
        didSet {
            if !self.bookmarkedOnly {
                self.title = "Search"
            }
        }
    }

    @IBOutlet var defaultRightBarButtonItem: UIBarButtonItem?

    // MARK: Fetch Predicate

    var searchPredicate: NSPredicate? {
        didSet {
            if let frc = self.fetchedResultsController {
                let request = frc.fetchRequest
                request.predicate = self.completePredicate

                do {
                    try frc.performFetch()
                } catch {
                    let error = error as NSError
                    assertionFailure("Error performing search fetch in session table: \(error)")
                }

                self.tableView.reloadData()
            }
        }
    }

    var completePredicate: NSPredicate? {
        var predicates: [NSPredicate] = []
        if self.bookmarkedOnly {
            let bookmarkPredicate = NSPredicate(format: "bookmarked == YES")
            predicates.append(bookmarkPredicate)
        }

        if let searchPredicate = self.searchPredicate {
            predicates.append(searchPredicate)
        }
        
        guard predicates.count > 0 else {
            return nil
        }

        let compound = NSCompoundPredicate.andPredicateWithSubpredicates(predicates)
        return compound
    }

    // MARK: Core Data

    private var managedObjectContext: NSManagedObjectContext { return self.coreDataController.managedObjectContext }

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
            let predicate = self.completePredicate
            let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
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

    // MARK: Editing

    /// Done button for editing the table view.
    /// Uses the same selector as `editButton`.
    private var doneButton: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("toggleEditing:"))
    }

    /// Edit button for editing the table view.
    /// Uses the same selector as `doneButton`.
    private var editButton: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: Selector("toggleEditing:"))
    }

    private var unfavoriteButton: UIBarButtonItem {
        return UIBarButtonItem(title: "Unfavorite", style: .Plain, target: self, action: Selector("removeFavorites"))
    }

    // MARK: Segue identifiers

    @IBInspectable var detailIdentifier: String!

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let sessionsFetchRequest = self.sessionsFetchRequest
        let frc = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        frc.delegate = self.fetchedResultsControllerDelegate
        self.fetchedResultsController = frc

        self.dataSource.prepareTableView(self.tableView)

        do {
            try frc.performFetch()
        } catch {
            let error = error as NSError
            NSLog("Error fetching sessions in session table: %@", error)
        }

        self.navigationItem.rightBarButtonItem = self.defaultRightBarButtonItem

        let searchBar = self.searchController.searchBar
        searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchBar
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let analytics = GAI.sharedInstance().defaultTracker {
            if self.bookmarkedOnly {
                analytics.set(kGAIScreenName, value: AnalyticsConstants.Screen.Favorites)
            } else {
                analytics.set(kGAIScreenName, value: AnalyticsConstants.Screen.ScheduleSearch)
            }
            let dict = GAIDictionaryBuilder.createScreenView().build() as NSDictionary as! [NSObject : AnyObject]
            analytics.send(dict)
        }

        self.searchController.searchBar.text = self.lastSearchText
    }

    // MARK: - Table View Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.dataSource.numberOfSectionsInTableView(tableView)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    // MARK: - Search Results Updating

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard searchController.active else {
            return
        }
        
        let searchText = searchController.searchBar.text
        self.lastSearchText = searchText

        var searchPredicate: NSPredicate?
        if case let searchText? = searchText where searchText.characters.count > 0 {
            // Case- and diacritic-insensitive searching
            searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        }
        self.searchPredicate = searchPredicate
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch(identifier) {
        case self.detailIdentifier:
            // Get the selected index path
            if let cell = sender as? UITableViewCell {
                self.selectedCellIndex = self.tableView.indexPathForCell(cell)
            }

            // Block the detail segue while in editing mode
            return !self.tableView.editing
        default:
            // Always allow other segues
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.searchController.active = false
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker

        switch (segue.identifier) {
        case .Some(self.detailIdentifier):
            let detailVC = segue.destinationViewController as! SessionViewController
            let selectedIndexPath = self.selectedCellIndex!
            let selectedSession = self.dataSource.session(selectedIndexPath)
            detailVC.session = selectedSession

            let dict = GAIDictionaryBuilder.createEventWithCategory(AnalyticsConstants.Category.Session, action: AnalyticsConstants.Actions.ViewDetails, label: selectedSession.name, value: nil).build() as NSDictionary as! [NSObject : AnyObject]
            analytics?.send(dict)
        default:
            // Segues we don't know about are fine.
            break
        }
    }
}
