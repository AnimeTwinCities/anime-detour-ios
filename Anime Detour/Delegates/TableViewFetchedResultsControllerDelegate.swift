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

    weak var tableView: UITableView?
    weak var customizer: TableViewFetchedResultsControllerCellCustomizer?

    // MARK: Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView?.beginUpdates()
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView?.endUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
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
        guard let tableView = self.tableView else {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        case .Move:
            // Likely to break for inserted or deleted sections.
            // Must fix later.
            tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        case .Update:
            switch (tableView.cellForRowAtIndexPath(indexPath), customizer) {
            case let (.Some(cell), .Some(customizer)):
                customizer.configure(cell, atIndexPath: indexPath)
            default:
                break
            }
        }
    }
}

// Declared 'class' to allow weak references.
protocol TableViewFetchedResultsControllerCellCustomizer: class {
    func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
}
