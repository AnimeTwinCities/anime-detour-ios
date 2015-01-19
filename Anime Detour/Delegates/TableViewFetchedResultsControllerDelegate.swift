//
//  TableViewFetchedResultsControllerDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/17/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

class TableViewFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private enum FetchedResultsControllerChange {
        case Object(anObject: AnyObject, indexPath: NSIndexPath?, type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
        case Section(sectionInfo: NSFetchedResultsSectionInfo, sectionIndex: Int, type: NSFetchedResultsChangeType)
    }

    var tableView: UITableView?
    private var sectionsChangedDuringUpdate: Bool = false
    private var cumulativeChanges: [FetchedResultsControllerChange] = []

    // MARK: Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.cumulativeChanges.removeAll(keepCapacity: false)
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView?.endUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let change = FetchedResultsControllerChange.Section(sectionInfo: sectionInfo, sectionIndex: sectionIndex, type: type)

        let tableView = self.tableView
        let indexSet = NSIndexSet(index: sectionIndex)
        switch type {
        case .Insert:
            tableView?.insertSections(indexSet, withRowAnimation: .Automatic)
        case .Delete:
            tableView?.deleteSections(indexSet, withRowAnimation: .Automatic)
        case .Move:
            assertionFailure("Unexpected fetched results controller section change type: \(type)")
        case .Update:
            assertionFailure("Unexpected fetched results controller section change type: \(type)")
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // Use with caution
        let (indexPath, newIndexPath): (NSIndexPath!, NSIndexPath!) = (indexPath, newIndexPath)
        if let tableView = self.tableView {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            case .Move:
                // Likely to break for inserted or deleted sections.
                // Must fix later.
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
            case .Update:
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
}
