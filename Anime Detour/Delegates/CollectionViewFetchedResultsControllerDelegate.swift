//
//  CollectionViewFetchedResultsControllerDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/11/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

class CollectionViewFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private enum FetchedResultsControllerChange {
        // Use the index paths with caution, as they may not always be set.
        // Declared force-unwrapped for convenience.
        case Object(anObject: AnyObject, indexPath: NSIndexPath!, type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)
        case Section(sectionInfo: NSFetchedResultsSectionInfo, sectionIndex: Int, type: NSFetchedResultsChangeType)
    }

    var collectionView: UICollectionView?
    var customizer: CollectionViewFetchedResultsControllerCellCustomizer?
    
    /// Track if any sections changed, and if any did, bail on attempting to apply updates,
    /// reloading the collection view instead.
    private var sectionsChangedDuringUpdate: Bool = false
    private var cumulativeChanges: [FetchedResultsControllerChange] = []

    // MARK: Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        cumulativeChanges.removeAll(keepCapacity: false)
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        defer {
            sectionsChangedDuringUpdate = false
        }
        
        guard let cv = collectionView else {
            return
        }
        
        guard !sectionsChangedDuringUpdate else {
            cv.reloadData()
            return
        }
        
        cv.performBatchUpdates({ () -> Void in
            for change in self.cumulativeChanges {
                switch change {
                case let .Object(_, indexPath, type, newIndexPath):
                    switch type {
                    case .Insert:
                        cv.insertItemsAtIndexPaths([newIndexPath])
                    case .Delete:
                        cv.deleteItemsAtIndexPaths([indexPath])
                    case .Move:
                        cv.deleteItemsAtIndexPaths([indexPath])
                        cv.insertItemsAtIndexPaths([newIndexPath])
                    case .Update:
                        switch (self.collectionView?.cellForItemAtIndexPath(indexPath), self.customizer) {
                        case let (.Some(cell), .Some(customizer)):
                            customizer.configure(cell, atIndexPath: indexPath)
                        default:
                            break
                        }
                    }
                case let .Section(_, sectionIndex, type):
                    let indexSet = NSIndexSet(index: sectionIndex)
                    switch type {
                    case .Insert:
                        cv.insertSections(indexSet)
                    case .Delete:
                        cv.deleteSections(indexSet)
                    default:
                        assertionFailure("Unexpected fetched results controller section change type: \(type)")
                    }
                }
            }
            }, completion: nil)
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        cumulativeChanges.append(.Section(sectionInfo: sectionInfo, sectionIndex: sectionIndex, type: type))
        
        sectionsChangedDuringUpdate = true
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {        
        cumulativeChanges.append(.Object(anObject: anObject, indexPath: indexPath, type: type, newIndexPath: newIndexPath))
    }
}

// Declared 'class' to allow weak references.
protocol CollectionViewFetchedResultsControllerCellCustomizer: class {
    func configure(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath)
}
