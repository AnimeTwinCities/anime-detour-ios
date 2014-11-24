//
//  SessionsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import CoreData
import Foundation
import UIKit

import ConScheduleKit
import FLCLFilmstripsCollectionLayout

class SessionsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
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
    lazy private var fetchedResultsControllerDelegate: CollectionViewFetchedResultsControllerDelegate = {
        let delegate = CollectionViewFetchedResultsControllerDelegate()
        delegate.collectionView = self.collectionView
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

    private var isDetail: Bool {
        get {
            return self.useLayoutToLayoutNavigationTransitions
        }
    }

    /// Fetched results controller currently in use
    private var fetchedResultsController: NSFetchedResultsController!

    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionCollectionViewDataSource!

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

    // Controls
    @IBOutlet var daySegmentedControl: UISegmentedControl?

    // Gesture recognizers
    @IBOutlet var horizontalScrollRecognizer: UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sessions"

        // If we are going to display detail cells, we do not need additional setup.
        // The class displaying us is assumed to have taken care of any setup required.
        if self.isDetail {
            return
        }

        // Set the names of the days on the day chooser segmented control
        if let daysControl = self.daySegmentedControl {
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"

            for (idx, date) in enumerate(self.days) {
                daysControl.setTitle(formatter.stringFromDate(date), forSegmentAtIndex: idx)
            }
        }

        let collectionView = self.collectionView!
        if let layout = (collectionView.collectionViewLayout as? FilmstripsCollectionLayout) {
            layout.itemSize = CGSize(width: 300, height: 88)
            layout.headerReferenceSize = CGSize(width: 300, height: 44)
        }

        var frc: NSFetchedResultsController = self.sessionsFetchedResultsController(self.sessionsFetchRequest)
        self.fetchedResultsController = frc
        self.dataSource = SessionCollectionViewDataSource(fetchedResultsController: frc, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController)
        self.dataSource.prepareCollectionView(collectionView)
        
        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: %@", error)
        }
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: Data Fetching

    func sessionsFetchedResultsController(fetchRequest: NSFetchRequest) -> NSFetchedResultsController {
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dataSource.numberOfSectionsInCollectionView(collectionView)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return self.dataSource.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return self.dataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }

    // MARK: Collection View Delegate

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Ignore selections if we're displaying detail cells.
        return !self.isDetail
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        let selectedSession = self.dataSource.session(indexPath)
        self.selectedSectionDate = selectedSession.start

        let singleSectionLayout = UICollectionViewFlowLayout()
        if let currentLayout = collectionView.collectionViewLayout as? FilmstripsCollectionLayout {
            singleSectionLayout.headerReferenceSize = currentLayout.headerReferenceSize
            singleSectionLayout.minimumInteritemSpacing = currentLayout.minimumInteritemSpacing
            singleSectionLayout.minimumLineSpacing = currentLayout.minimumLineSpacing
        }
        let sectionVC = SessionsViewController(collectionViewLayout: singleSectionLayout)
        sectionVC.useLayoutToLayoutNavigationTransitions = true
        self.navigationController?.showViewController(sectionVC, sender: self)
    }

    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? SessionCollectionViewCell {
            let vm = cell.viewModel
            if let startDate = vm?.session.start {
                if let dateIdx = self.dayIndex(startDate) {
                    self.daySegmentedControl?.selectedSegmentIndex = dateIdx
                }
            }
        }
    }

    // MARK: Collection View Delegate Flow Layout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 300, height: 200)
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let detailVC = segue.destinationViewController as? SessionViewController {
            detailVC.session = self.selectedSession!
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
            self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
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

extension SessionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer != self.horizontalScrollRecognizer {
            return true
        }

        if let layout = self.collectionView?.collectionViewLayout as? FilmstripsCollectionLayout {
            let collectionView = self.collectionView!
            let location = touch.locationInView(collectionView)

            // Check if the touch is in a collection view cell. Return true if so.
            let subview = collectionView.hitTest(location, withEvent: nil)
            var inCell = false
            var currentView = subview
            while let superview = currentView?.superview {
                if superview == collectionView {
                    break
                }
                if superview is UICollectionViewCell {
                    inCell = true
                    break
                }

                currentView = superview
            }

            return inCell
        }

        return false
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.horizontalScrollRecognizer {
            let recognizer = self.horizontalScrollRecognizer!
            let velocity = recognizer.velocityInView(self.collectionView)
            let horizontal = abs(velocity.x) > abs(velocity.y)
            return horizontal
        }
        
        return true
    }
}

private class CollectionViewFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private enum FetchedResultsControllerChange {
        case Object(anObject: AnyObject, indexPath: NSIndexPath?, type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
        case Section(sectionInfo: NSFetchedResultsSectionInfo, sectionIndex: Int, type: NSFetchedResultsChangeType)
    }

    var collectionView: UICollectionView?
    private var sectionsChangedDuringUpdate: Bool = false
    private var cumulativeChanges: [FetchedResultsControllerChange] = []

    // MARK: Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.cumulativeChanges.removeAll(keepCapacity: false)
    }

    private func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if let cv = self.collectionView {
            cv.performBatchUpdates({ () -> Void in
                for change in self.cumulativeChanges {
                    switch change {
                    case let .Object(anObject, indexPath, type, newIndexPath):
                        switch type {
                        case .Insert:
                            cv.insertItemsAtIndexPaths([newIndexPath!])
                        case .Delete:
                            cv.deleteItemsAtIndexPaths([indexPath!])
                        case .Move:
                            if self.sectionsChangedDuringUpdate {
                                cv.deleteItemsAtIndexPaths([indexPath!])
                                cv.insertItemsAtIndexPaths([newIndexPath!])

                                self.sectionsChangedDuringUpdate = false
                            } else {
                                cv.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                            }
                        case .Update:
                            cv.reloadItemsAtIndexPaths([indexPath!])
                        }
                    case let .Section(sectionInfo, sectionIndex, type):
                        let indexSet = NSIndexSet(index: sectionIndex)
                        switch type {
                        case .Insert:
                            cv.insertSections(indexSet)
                        case .Delete:
                            cv.deleteSections(indexSet)
                        default:
                            assertionFailure("Unexpected fetched results controller section change type: \(type)")
                        }
                        
                        self.sectionsChangedDuringUpdate = true
                    }
                }
            }, completion: nil)
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        self.cumulativeChanges.append(.Section(sectionInfo: sectionInfo, sectionIndex: sectionIndex, type: type))

    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        self.cumulativeChanges.append(.Object(anObject: anObject, indexPath: indexPath, type: type, newIndexPath: newIndexPath))
    }
}