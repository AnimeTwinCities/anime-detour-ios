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

class FavoriteSessionsTableViewController: UITableViewController {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy var coreDataController = CoreDataController.sharedInstance
    lazy var userDataController = UserDataController.sharedInstance

    // MARK: Core Data

    private var sessionsManagedObjectContext: NSManagedObjectContext { return self.coreDataController.managedObjectContext! }
    private var bookmarksManagedObjectContext: NSManagedObjectContext { return self.userDataController.managedObjectContext! }

    /// Fetched results controller over `SessionBookmark`s.
    lazy private var fetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = self.bookmarksFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.bookmarksManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()

    lazy private var fetchedResultsControllerDelegate: TableViewFetchedResultsControllerDelegate = {
        let delegate = TableViewFetchedResultsControllerDelegate()
        delegate.tableView = self.tableView
        return delegate
    }()

    /**
    Fetch request for all SessionBookmarks, sorted by the `Session`'s ID. Creates a new fetch request on every access.
    */
    private var bookmarksFetchRequest: NSFetchRequest {
        get {
            let sortDescriptors = [NSSortDescriptor(key: "sessionID", ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: SessionBookmark.entityName)
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }

    // MARK: Table view

    /**
    Table view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionBookmarkDataSource!

    private var timeZone: NSTimeZone = NSTimeZone(name: "America/Chicago")! // hard-coded for Anime-Detour

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

        let frc = self.fetchedResultsController

        self.dataSource = SessionBookmarkDataSource(fetchedResultsController: frc, timeZone: self.timeZone, coreDataController: self.coreDataController, userDataController: self.userDataController)
        self.dataSource.prepareTableView(self.tableView)

        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: %@", error)
        }
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

    // MARK: - Editing

    @IBAction func toggleEditing(sender: AnyObject?) {
        let isEditing = !self.tableView.editing
        self.tableView.setEditing(isEditing, animated: true)

        let navItem = self.navigationItem
        if isEditing {
            navItem.leftBarButtonItem = self.unfavoriteButton
            navItem.rightBarButtonItem = self.doneButton
        } else {
            navItem.leftBarButtonItem = nil
            navItem.rightBarButtonItem = self.editButton
        }
    }

    @IBAction func removeFavorites() {
        let selectedIndexPaths = self.tableView.indexPathsForSelectedRows()
        let selectedObjects = selectedIndexPaths?.map { return $0 as NSIndexPath }.map(self.fetchedResultsController.objectAtIndexPath)
        if let selectedBookmarks =  selectedObjects as? [SessionBookmark] {
            let moc = self.userDataController.managedObjectContext!
            for bookmark in selectedBookmarks {
                moc.deleteObject(bookmark)
            }

            moc.save(nil)
        }
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        switch(identifier) {
        case .Some(self.detailIdentifier):
            // Block the detail segue while in editing mode
            return !self.tableView.editing
        default:
            // Always allow other segues
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(self.detailIdentifier):
            let detailVC = segue.destinationViewController as SessionViewController
            let selectedSession = self.tableView.indexPathForSelectedRow().map(self.dataSource.session)
            detailVC.session = selectedSession!
        default:
            // Segues we don't know about are fine.
            break
        }
    }
}
