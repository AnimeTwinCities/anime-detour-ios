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
    fileprivate var imagesURLSession = URLSession.shared

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

    /// Fetched results controller over `Session`s.
    fileprivate var fetchedResultsController: NSFetchedResultsController<Session>?

    lazy fileprivate var fetchedResultsControllerDelegate: TableViewFetchedResultsControllerDelegate = {
        let delegate = TableViewFetchedResultsControllerDelegate()
        delegate.tableView = self.tableView
        return delegate
    }()

    /**
    Fetch request for all SessionBookmarks, sorted by the `Session`'s ID. Creates a new fetch request on every access.
    */
    fileprivate var sessionsFetchRequest: NSFetchRequest<Session> {
        get {
            let predicate = completePredicate
            let sortDescriptors = [NSSortDescriptor(key: Session.Keys.startTime.rawValue, ascending: true), NSSortDescriptor(key: Session.Keys.name.rawValue, ascending: true)]
            let sessionsFetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
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

    fileprivate var lastSearchText: String?

    // MARK: Table view

    /**
     Table view data source that we call through to from our data
     source methods.
     
     Our cells don't allow adding or removing favorites, so we don't need to set a delegate.
     */
    lazy fileprivate var dataSource: SessionDataSource! = SessionDataSource(fetchedResultsController: self.fetchedResultsController!, cellDelegate: nil, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession)

    fileprivate var timeZone: TimeZone = TimeZone(identifier: "America/Chicago")! // hard-coded for Anime-Detour

    fileprivate var selectedCellIndex: IndexPath?
    
    // MARK: Segue identifiers

    @IBInspectable var detailIdentifier: String!

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let frc = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: AppDelegate.persistentContainer.viewContext, sectionNameKeyPath: "start", cacheName: nil)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.text = lastSearchText
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }

    // MARK: - Search Results Updating

    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else {
            return
        }
        
        let searchText = searchController.searchBar.text
        lastSearchText = searchText

        var searchPredicate: NSPredicate?
        defer {
            self.searchPredicate = searchPredicate
        }
        
        if case let searchText? = searchText , searchText.characters.count > 0 {
            // Case- and diacritic-insensitive searching
            searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        }
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch(identifier) {
        case detailIdentifier:
            // Get the selected index path
            let cell = sender as! UITableViewCell
            selectedCellIndex = tableView.indexPath(for: cell)

            // Block the detail segue while in editing mode
            return !tableView.isEditing
        default:
            // Always allow other segues
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        searchController.isActive = false
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker

        switch (segue.identifier) {
        case detailIdentifier?:
            let detailVC = segue.destination as! SessionViewController
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
