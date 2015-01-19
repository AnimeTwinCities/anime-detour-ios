//
//  SessionsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import Foundation
import UIKit

import ConScheduleKit

class SessionsViewController: UITableViewController {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy var userDataController = UserDataController.sharedInstance
    lazy private var managedObjectContext: NSManagedObjectContext = {
        return CoreDataController.sharedInstance.managedObjectContext!
    }()
    lazy private var sessionsFetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = self.sessionsFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()
    lazy private var allSessionsPredicate: NSPredicate = NSPredicate(value: true)
    lazy private var fetchedResultsControllerDelegate: TableViewFetchedResultsControllerDelegate = {
        let delegate = TableViewFetchedResultsControllerDelegate()
        delegate.tableView = self.tableView
        return delegate
    }()

    private var sessionsFetchRequest: NSFetchRequest {
        get {
            let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: "Session")
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }

    /// Fetched results controller currently in use
    private var fetchedResultsController: NSFetchedResultsController!

    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionTableViewDataSource!

    // Selections
    private var selectedIndexPath: NSIndexPath?
    private var selectedSession: Session?
    private var selectedSectionDate: NSDate?

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

    // Controls
    @IBOutlet var daySegmentedControl: UISegmentedControl?

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sessions"

        // Set the names of the days on the day chooser segmented control
        if let daysControl = self.daySegmentedControl {
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"

            for (idx, date) in enumerate(self.days) {
                daysControl.setTitle(formatter.stringFromDate(date), forSegmentAtIndex: idx)
            }
        }

        var frc: NSFetchedResultsController = self.sessionsFetchedResultsController(self.sessionsFetchRequest)
        self.fetchedResultsController = frc
        self.dataSource = SessionTableViewDataSource(fetchedResultsController: frc, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController)
        self.dataSource.prepareTableView(self.tableView)
        
        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: %@", error)
        }
    }

    // MARK: - Data Fetching

    func sessionsFetchedResultsController(fetchRequest: NSFetchRequest) -> NSFetchedResultsController {
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
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
        if let detailVC = segue.destinationViewController as? SessionViewController {
            let selectedSession = self.tableView.indexPathForSelectedRow().map(self.dataSource.session)
            detailVC.session = selectedSession!
        }
    }
}

/// Day selection indicator logic
extension SessionsViewController {
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
        fetchRequest.entity = NSEntityDescription.entityForName("Session", inManagedObjectContext: moc)
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
