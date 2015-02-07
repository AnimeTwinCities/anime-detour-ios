//
//  SessionTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import Foundation
import UIKit

import AnimeDetourAPI

class SessionTableViewController: UITableViewController {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy var userDataController = UserDataController.sharedInstance
    @IBInspectable var isBookmarks: Bool = false

    // MARK: Core Data

    lazy private var managedObjectContext: NSManagedObjectContext = CoreDataController.sharedInstance.managedObjectContext!

    /// Fetched results controller over `Session`s.
    lazy private var fetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = self.sessionsFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()

    /// Type name for which the Session list will be filtered.
    /// Updating this property will update out `title`.
    /// Must not be changed before `fetchedResultsController` is created.
    private var filteredType: SelectedSessionType = .All {
        didSet {
            if self.filteredType == oldValue {
                return
            }

            self.title = self.filteredTitle(self.filteredType)

            self.fetchedResultsController.fetchRequest.predicate = self.completePredicate

            var error: NSError?
            self.fetchedResultsController.performFetch(&error)

            if let error = error {
                let errorDesc = error.userInfo?[NSLocalizedDescriptionKey] as? String ?? "Unknown error"
                println("Error performing Session fetch: %@", errorDesc)
            }

            self.tableView.reloadData()
        }
    }

    private var completePredicate: NSPredicate? {
        let filterPredicate = self.filteredSessionsPredicate
        let bookmarkedPredicate: NSPredicate? = nil // needs to be rethought since the bookmarked status of a Session is not on the Session itself
        var predicates = [NSPredicate]()
        if let filterPredicate = self.filteredSessionsPredicate {
            predicates.append(filterPredicate)
        }
        if let bookmarkedPredicate = bookmarkedPredicate {
            predicates.append(bookmarkedPredicate)
        }
        let completePredicate = NSCompoundPredicate.andPredicateWithSubpredicates(predicates)
        return completePredicate
    }
    private var filteredSessionsPredicate: NSPredicate? {
        switch self.filteredType {
        case .All:
            return nil
        case let .Named(type):
            let begins = NSPredicate(format: "type BEGINSWITH %@", type)!
            let contains = NSPredicate(format: "type CONTAINS %@", ", " + type + ",")!
            let ends = NSPredicate(format: "type ENDSWITH %@", ", " + type)!
            let pred = NSCompoundPredicate.orPredicateWithSubpredicates([begins, contains, ends])
            return pred
        }
    }
    lazy private var fetchedResultsControllerDelegate: TableViewFetchedResultsControllerDelegate = {
        let delegate = TableViewFetchedResultsControllerDelegate()
        delegate.tableView = self.tableView
        return delegate
    }()

    /**
    Fetch request for all Sessions, sorted by start time then name. Creates a new fetch request on every access.
    */
    private var sessionsFetchRequest: NSFetchRequest {
        get {
            let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: Session.entityName)
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }

    // MARK: Table view

    /**
    Table view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionTableViewDataSource!


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

    // MARK: Selections
    private var selectedIndexPath: NSIndexPath?
    private var selectedSession: Session?
    private var selectedSectionDate: NSDate?

    // MARK: Day indicator
    lazy private var dayScroller: SessionDayScroller = SessionDayScroller(fetchedResultsController: self.fetchedResultsController, targetView: .TableView(self.tableView), daySegmentedControl: self.daySegmentedControl)
    private var timeZone: NSTimeZone = NSTimeZone(name: "America/Chicago")! // hard-coded for Anime-Detour

    /**
    Create an array of dates, set to midnight, of each day of the con.

    Hard-coded for Anime Detour.
    */
    private lazy var days: [NSDate] = {
        // Components for Friday at midnight
        let components = NSDateComponents()
//        components.year = 2015
//        components.month = 3
//        components.day = 27
        components.year = 2014
        components.month = 4
        components.day = 4
        components.hour = 0
        components.minute = 0
        components.timeZone = self.timeZone

        let calendar = NSCalendar.currentCalendar()
        let friday = calendar.dateFromComponents(components)!
        components.day += 1
        let saturday = calendar.dateFromComponents(components)!
        components.day += 1
        let sunday = calendar.dateFromComponents(components)!

        return [friday, saturday, sunday]
    }()

    // MARK: Controls

    @IBOutlet var daySegmentedControl: UISegmentedControl?

    // MARK: Segue identifiers

    private class var detailSegueIdentifier: String { return "SessionDetail" }
    private class var filterSegueIdentifier: String { return "FilterSessions" }

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.filteredTitle(self.filteredType)

        // Set the names of the days on the day chooser segmented control
        if let daysControl = self.daySegmentedControl {
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"

            for (idx, date) in enumerate(self.days) {
                daysControl.setTitle(formatter.stringFromDate(date), forSegmentAtIndex: idx)
            }
        }

        let frc = self.fetchedResultsController

        self.dataSource = SessionTableViewDataSource(fetchedResultsController: frc, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController)
        self.dataSource.prepareTableView(self.tableView)

        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: %@", error)
        }
    }

    // MARK: Visual properties

    func filteredTitle(filteredSessionType: SelectedSessionType) -> String {
        let unfilteredTitle = self.isBookmarks ? "Favorite Sessions" : "Sessions"
        switch self.filteredType {
        case .All:
            return unfilteredTitle
        case let .Named(type):
            return type
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

    // MARK: - Table View Delegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.dayScroller.willDisplayItemAtIndexPath(indexPath)
    }

    // MARK: - Scroll View Delegate

    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.dayScroller.scrollViewDidEndScrollingAnimation()
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

        // TODO: remove bookmarked items
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        switch(identifier) {
        case .Some(SessionTableViewController.detailSegueIdentifier):
            // Block the detail segue while in editing mode
            return !self.tableView.editing
        default:
            // Always allow other segues
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(SessionTableViewController.detailSegueIdentifier):
            let detailVC = segue.destinationViewController as SessionViewController
            let selectedSession = self.tableView.indexPathForSelectedRow().map(self.dataSource.session)
            detailVC.session = selectedSession!
        case .Some(SessionTableViewController.filterSegueIdentifier):
            let navController = segue.destinationViewController as UINavigationController
            let filterVC = navController.topViewController as SessionFilterTableViewController
            filterVC.selectedType = self.filteredType
            filterVC.sessionTypes = { () -> [String] in
                let typeKey = "type"
                let request = NSFetchRequest(entityName: Session.entityName)
                request.propertiesToFetch = [ typeKey ]
                request.resultType = NSFetchRequestResultType.DictionaryResultType
                request.returnsDistinctResults = true

                if let results = self.managedObjectContext.executeFetchRequest(request, error: nil) as? [[String:String]] {
                    // This is probably very slow...
                    var types = results.map { dict -> String in return dict[typeKey]! }.flatMap { types in types.componentsSeparatedByString(",") }
                    var uniqueing = [String:Void]()
                    for type in types {
                        uniqueing[type] = ()
                    }

                    let uniqueTypes = uniqueing.keys.array
                    return sorted(uniqueTypes)
                }

                return []
            }()
        default:
            // Segues we don't know about are fine.
            break
        }
    }

    @IBAction func unwindAfterFiltering(segue: UIStoryboardSegue) {
        let filterVC = segue.sourceViewController as SessionFilterTableViewController
        self.filteredType = filterVC.selectedType

        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

private class SessionDayScroller {
    private enum TargetView {
        case CollectionView(UICollectionView)
        case TableView(UITableView)
    }

    private let fetchedResultsController: NSFetchedResultsController
    private let targetView: TargetView
    private let daySegmentedControl: UISegmentedControl?

    /// `true` indicates that the view is currently scrolling to the first item on
    /// a particular day.
    private(set) var scrollingToDay = false

    /**
    :param: days The days
    */
    init(fetchedResultsController: NSFetchedResultsController, targetView: TargetView, daySegmentedControl: UISegmentedControl?) {
        self.fetchedResultsController = fetchedResultsController
        self.targetView = targetView
        self.daySegmentedControl = daySegmentedControl
    }

    /**
    Find the index path of the first Session with a start time of `date` or later
    */
    private func indexPathOfSection(date: NSDate) -> NSIndexPath? {
        let predicate = NSPredicate(format: "start >= %@", argumentArray: [date])
        let moc = self.fetchedResultsController.managedObjectContext
        let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: moc)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        if let results = moc.executeFetchRequest(fetchRequest, error: nil) as? [Session] {
            if let first = results.first {
                return self.fetchedResultsController.indexPathForObject(first)
            }
        }

        return nil
    }

    /// Scroll to the first session for the day
    func scroll(date: NSDate) {
        if let indexPath = self.indexPathOfSection(date) {
            self.scrollingToDay = true
            switch self.targetView {
            case let .CollectionView(cv):
                fatalError("Collection view support not yet implemented")
            case let .TableView(tv):
                tv.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
            }
        }
    }

    func willDisplayItemAtIndexPath(indexPath: NSIndexPath) {
        if self.scrollingToDay {
            return
        }

        if let session = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Session {
            let startDate = session.start
            if let startDateIdx = self.indexPathOfSection(startDate)?.section {
                self.daySegmentedControl?.selectedSegmentIndex = startDateIdx
            }
        }
    }

    // MARK: - Scroll View Delegate

    func scrollViewDidEndScrollingAnimation() {
        self.scrollingToDay = false
    }
}

// MARK: - Day selection indicator logic
extension SessionTableViewController {
    @IBAction func goToDay(sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex
        let day = self.days[selectedIdx]
        self.dayScroller.scroll(day)
    }

    /**
    Finds the index of the date in `self.days` which is the same day as `date`.

    :returns: An index, or `nil` if no matching date was found.
    */
    private func dayIndex(date: NSDate) -> Int? {
        let days = self.days
        let dateAsInterval = date.timeIntervalSinceReferenceDate
        let fridayAsInterval = days[0].timeIntervalSinceReferenceDate
        let saturdayAsInterval = days[1].timeIntervalSinceReferenceDate
        let sundayAsInterval = days[2].timeIntervalSinceReferenceDate

        var dateIdx: Int?
        switch dateAsInterval {
        case fridayAsInterval ..< saturdayAsInterval:
            dateIdx = 0
        case saturdayAsInterval ..< sundayAsInterval:
            dateIdx = 1
        case sundayAsInterval ..< NSDate.distantFuture().timeIntervalSinceReferenceDate:
            dateIdx = 2
        default:
            break
        }

        return dateIdx
    }
}
