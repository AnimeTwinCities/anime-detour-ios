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
    fileprivate enum FetchedResultsControllerChange {
        // Use the index paths with caution, as they may not always be set.
        // Declared force-unwrapped for convenience.
        case object(anObject: AnyObject, indexPath: IndexPath?, type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
        case section(sectionInfo: NSFetchedResultsSectionInfo, sectionIndex: Int, type: NSFetchedResultsChangeType)
    }

    var collectionView: UICollectionView?
    var customizer: CollectionViewFetchedResultsControllerCellCustomizer?
    
    /// Track if any sections changed, and if any did, bail on attempting to apply updates,
    /// reloading the collection view instead.
    fileprivate var sectionsChangedDuringUpdate: Bool = false
    fileprivate var cumulativeChanges: [FetchedResultsControllerChange] = []

    // MARK: Fetched Results Controller Delegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        cumulativeChanges.removeAll(keepingCapacity: false)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
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
                case let .object(_, indexPath, type, newIndexPath):
                    switch type {
                    case .insert:
                        cv.insertItems(at: [newIndexPath!])
                    case .delete:
                        cv.deleteItems(at: [indexPath!])
                    case .move:
                        cv.deleteItems(at: [indexPath!])
                        cv.insertItems(at: [newIndexPath!])
                    case .update:
                        switch (self.collectionView?.cellForItem(at: indexPath!), self.customizer) {
                        case let (.some(cell), .some(customizer)):
                            customizer.configure(cell, atIndexPath: indexPath!)
                        default:
                            break
                        }
                    }
                case let .section(_, sectionIndex, type):
                    let indexSet = IndexSet(integer: sectionIndex)
                    switch type {
                    case .insert:
                        cv.insertSections(indexSet)
                    case .delete:
                        cv.deleteSections(indexSet)
                    default:
                        assertionFailure("Unexpected fetched results controller section change type: \(type)")
                    }
                }
            }
            }, completion: nil)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        cumulativeChanges.append(.section(sectionInfo: sectionInfo, sectionIndex: sectionIndex, type: type))
        
        sectionsChangedDuringUpdate = true
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {        
        cumulativeChanges.append(.object(anObject: anObject as AnyObject, indexPath: indexPath, type: type, newIndexPath: newIndexPath))
    }
}

// Declared 'class' to allow weak references.
protocol CollectionViewFetchedResultsControllerCellCustomizer: class {
    func configure(_ cell: UICollectionViewCell, atIndexPath indexPath: IndexPath)
}
