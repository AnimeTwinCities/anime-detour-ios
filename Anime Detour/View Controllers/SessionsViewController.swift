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
        let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        let sessionsFetchRequest = NSFetchRequest(entityName: "Session")
        sessionsFetchRequest.sortDescriptors = sortDescriptors

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()
    lazy private var fetchedResultsControllerDelegate: CollectionViewFetchedResultsControllerDelegate = {
        let delegate = CollectionViewFetchedResultsControllerDelegate()
        delegate.collectionView = self.collectionView
        return delegate
    }()

    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionCollectionViewDataSource!
    private var selectedSession: Session?

    private let sessionDetailSegueIdentifier = "SessionDetailSegueIdentifier"
    private let sessionFilterSegueIdentifier = "SessionFilterSegueIdentifier"

    /// Filter sections to only include those matching this name exactly (TODO)
    var sectionFilterPredicate: String?

    // Gesture recognizers
    @IBOutlet var horizontalScrollRecognizer: UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sessions"

        let collectionView = self.collectionView
        if let layout = (collectionView.collectionViewLayout as? FilmstripsFlowLayout) {
            layout.itemSize = CGSize(width: 300, height: 120)
            layout.headerReferenceSize = CGSize(width: 300, height: 44)
        }

        let frc = self.sessionsFetchedResultsController
        self.dataSource = SessionCollectionViewDataSource(imagesURLSession: self.imagesURLSession, fetchedResultsController: frc)
        self.dataSource.prepareCollectionView(collectionView)
        
        var fetchError: NSError?
        let success = frc.performFetch(&fetchError)
        if let error = fetchError {
            NSLog("Error fetching sessions: \(error)")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.hidesBarsOnSwipe = true
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedSession = self.dataSource.session(indexPath)
        
        self.performSegueWithIdentifier(self.sessionDetailSegueIdentifier, sender: self)
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
        } else if let detailVC = segue.destinationViewController as? SessionsViewController {
            detailVC.useLayoutToLayoutNavigationTransitions = true
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