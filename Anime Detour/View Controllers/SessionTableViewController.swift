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

    // MARK: Core Data

    lazy private var managedObjectContext: NSManagedObjectContext = {
        return CoreDataController.sharedInstance.managedObjectContext!
    }()
    lazy private var sessionsFetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = self.sessionsFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()

    /// Type name for which the Session list will be filtered.
    /// Must not be changed before `fetchedResultsController` is created.
    private var filteredType: String? {
        didSet {
            if self.filteredType == oldValue {
                return
            }

            self.fetchedResultsController.fetchRequest.predicate = self.filteredSessionsPredicate

            var error: NSError?
            self.fetchedResultsController.performFetch(&error)

            if let error = error {
                let errorDesc = error.userInfo?[NSLocalizedDescriptionKey] as? String ?? "Unknown error"
                println("Error performing Session fetch: %@", errorDesc)
            }

            self.tableView.reloadData()
        }
    }
    private var filteredSessionsPredicate: NSPredicate? {
        if let filteredType = self.filteredType {
            let begins = NSPredicate(format: "type BEGINSWITH %@", filteredType)!
            let contains = NSPredicate(format: "type CONTAINS %@", ", " + filteredType + ",")!
            let ends = NSPredicate(format: "type ENDSWITH %@", ", " + filteredType)!
            let pred = NSCompoundPredicate.orPredicateWithSubpredicates([begins, contains, ends])
            return pred
        } else {
            return nil
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

    /// Fetched results controller currently in use
    private var fetchedResultsController: NSFetchedResultsController!

    // MARK: Table view

    /**
    Table view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionTableViewDataSource!

    // MARK: Selections
    private var selectedIndexPath: NSIndexPath?
    private var selectedSession: Session?
    private var selectedSectionDate: NSDate?

    // MARK: Day indicator

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

    /// `true` indicates that the view is currently scrolling to the first item on
    /// a particular day.
    private var scrollingToDay = false

    // MARK: Controls

    @IBOutlet var daySegmentedControl: UISegmentedControl?

    // MARK: - Segue identifiers

    private class var detailSegueIdentifier: String { return "SessionDetail" }
    private class var filterSegueIdentifier: String { return "FilterSessions" }

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the names of the days on the day chooser segmented control
        if let daysControl = self.daySegmentedControl {
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"

            for (idx, date) in enumerate(self.days) {
                daysControl.setTitle(formatter.stringFromDate(date), forSegmentAtIndex: idx)
            }
        }

        self.fetchedResultsController = self.sessionsFetchedResultsController
        let frc = self.fetchedResultsController

        self.dataSource = SessionTableViewDataSource(fetchedResultsController: frc, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController)
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

    // MARK: - Table View Delegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.scrollingToDay {
            return
        }

        if let cell = cell as? SessionTableViewCell {
            let startDate = cell.viewModel?.session.start
            if let startDateIdx = startDate.flatMap(self.dayIndex) {
                self.daySegmentedControl?.selectedSegmentIndex = startDateIdx
            }
        }
    }

    // MARK: - Scroll View Delegate

    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.scrollingToDay = false
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(SessionTableViewController.detailSegueIdentifier):
            let detailVC = segue.destinationViewController as SessionViewController
            let selectedSession = self.tableView.indexPathForSelectedRow().map(self.dataSource.session)
            detailVC.session = selectedSession!
        case .Some(SessionTableViewController.filterSegueIdentifier):
            let navController = segue.destinationViewController as UINavigationController
            let filterVC = navController.topViewController as SessionFilterTableViewController
            filterVC.selectedType = self.filteredType.map { .Named($0) } ?? .All
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

                    types = uniqueing.keys.array
                    sort(&types)
                    return types
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
        switch filterVC.selectedType {
        case .All:
            self.filteredType = nil
        case let .Named(typeName):
            self.filteredType = typeName
        }

        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - Day selection indicator logic
extension SessionTableViewController {
    @IBAction func goToDay(sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex

        // Scroll to the first session for the selected day
        let date = self.days[selectedIdx]
        if let indexPath = self.indexPath(date) {
            self.scrollingToDay = true
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }

    /**
    Find the index path of the first Session with a start time of `date` or later
    */
    private func indexPath(date: NSDate) -> NSIndexPath? {
        let predicate = NSPredicate(format: "start >= %@", argumentArray: [date])
        let moc = self.managedObjectContext
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
