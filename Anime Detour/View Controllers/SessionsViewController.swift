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
import FilmstripsFlowLayout

class SessionsViewController: UICollectionViewController, UIGestureRecognizerDelegate {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy private var managedObjectContext: NSManagedObjectContext = {
        return ConModelsController.sharedInstance.managedObjectContext!
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
    private var singleSectionSessionsPredicate: NSPredicate {
        get {
            return NSPredicate(format: "start == %@", argumentArray: [self.selectedSectionDate!])
        }
    }

    private var isSingleSection: Bool {
        get {
            return self.useLayoutToLayoutNavigationTransitions
        }
    }

    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionCollectionViewDataSource!

    // Selections
    private var selectedIndexPath: NSIndexPath?
    private var selectedSession: Session?
    private var selectedSectionDate: NSDate?

    private let sessionDetailSegueIdentifier = "SessionDetailSegueIdentifier"
    private let sessionFilterSegueIdentifier = "SessionFilterSegueIdentifier"

    // Gesture recognizers
    @IBOutlet var horizontalScrollRecognizer: UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sessions"

        // If we are going to display only a single section, we do not need additional setup.
        // The class displaying us is assumed to have taken care of any setup required.
        if self.isSingleSection {
            return
        }

        self.navigationController?.delegate = self

        let collectionView = self.collectionView
        if let layout = (collectionView.collectionViewLayout as? FilmstripsFlowLayout) {
            layout.itemSize = CGSize(width: 300, height: 120)
            layout.headerReferenceSize = CGSize(width: 300, height: 44)
        }

        var frc: NSFetchedResultsController = self.sessionsFetchedResultsController(self.sessionsFetchRequest)
        self.dataSource = SessionCollectionViewDataSource(imagesURLSession: self.imagesURLSession, fetchedResultsController: frc)
        self.dataSource.prepareCollectionView(collectionView)
        
        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: \(error)")
        }
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()
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
        // Ignore selections if we're displaying only a single section.
        return !self.isSingleSection
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        let selectedSession = self.dataSource.session(indexPath)
        self.selectedSectionDate = selectedSession.start

        let singleSectionLayout = UICollectionViewFlowLayout()
        if let currentLayout = self.collectionView.collectionViewLayout as? FilmstripsFlowLayout {
            singleSectionLayout.itemSize = currentLayout.itemSize
            singleSectionLayout.headerReferenceSize = currentLayout.headerReferenceSize
            singleSectionLayout.minimumInteritemSpacing = currentLayout.minimumInteritemSpacing
            singleSectionLayout.minimumLineSpacing = currentLayout.minimumLineSpacing
        }
        let sectionVC = SessionsViewController(collectionViewLayout: singleSectionLayout)
        sectionVC.useLayoutToLayoutNavigationTransitions = true
        self.navigationController?.showViewController(sectionVC, sender: self)
    }

    // MARK: Gesture Recognizer Delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == self.horizontalScrollRecognizer && self.collectionView.collectionViewLayout is FilmstripsFlowLayout {
            let collectionView = self.collectionView
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
        
        return true
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
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let detailVC = segue.destinationViewController as? SessionViewController {
            detailVC.session = self.selectedSession!
        }
    }
}

extension SessionsViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        // TODO: The transition triggering `willShowViewController` may be cancelled.
        // This leads to bad state when transitioning from a single section view to the
        // full session list. Guard logic in the single section VC's `viewWillAppear`
        // may be useful to solve this issue.

        if self.selectedIndexPath == nil {
            return
        }

        let collectionView = self.collectionView
        let section = self.selectedIndexPath!.section

        // NOTE: Relies on `viewController` automatically becoming the delegate of the collection view
        // if this is a `useLayoutToLayoutNavigationTransitions` push or pop transition.
        if viewController != self {
            let lastSection = collectionView.numberOfSections() - 1

            if let pushed = viewController as? SessionsViewController {
                collectionView.performBatchUpdates({ () -> Void in
                    let predicate = self.singleSectionSessionsPredicate
                    let fetchRequest = self.sessionsFetchRequest
                    fetchRequest.predicate = predicate

                    var frc: NSFetchedResultsController = self.sessionsFetchedResultsController(fetchRequest)
                    self.dataSource = SessionCollectionViewDataSource(imagesURLSession: self.imagesURLSession, fetchedResultsController: frc)

                    var fetchError: NSError?
                    let success = frc.performFetch(&fetchError)
                    if let error = fetchError {
                        NSLog("Error fetching sessions: \(error)")
                    }

                    let indexSet = NSMutableIndexSet()
                    if section > 0 {
                        let firstRange = NSMakeRange(0, section)
                        indexSet.addIndexesInRange(firstRange)
                    }

                    if section < lastSection {
                        let lastRange = NSMakeRange(section + 1, lastSection - section)
                        indexSet.addIndexesInRange(lastRange)
                    }

                    collectionView.deleteSections(indexSet)
                    }, completion: nil)

                assert(collectionView.numberOfSections() == 1, "Collection view should have only one section after push")
            }
        } else {
            assert(collectionView.numberOfSections() == 1, "Collection view should have only one section before push")

            collectionView.performBatchUpdates({ () -> Void in
                let predicate = self.allSessionsPredicate
                let fetchRequest = self.sessionsFetchRequest
                fetchRequest.predicate = predicate

                var frc: NSFetchedResultsController = self.sessionsFetchedResultsController(fetchRequest)
                self.dataSource = SessionCollectionViewDataSource(imagesURLSession: self.imagesURLSession, fetchedResultsController: frc)

                var fetchError: NSError?
                let success = frc.performFetch(&fetchError)
                if let error = fetchError {
                    NSLog("Error fetching sessions: \(error)")
                }

                let lastSection = frc.sections!.count - 1

                let indexSet = NSMutableIndexSet()
                if section > 0 {
                    let firstRange = NSMakeRange(0, section)
                    indexSet.addIndexesInRange(firstRange)
                }

                if section < lastSection {
                    let lastRange = NSMakeRange(section + 1, lastSection - section)
                    indexSet.addIndexesInRange(lastRange)
                }
                collectionView.insertSections(indexSet)
                }, completion: nil)
        }
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
        // empty
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