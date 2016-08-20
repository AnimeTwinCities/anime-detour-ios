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

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let tableView = self.tableView
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView?.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView?.deleteSections(indexSet, with: .automatic)
        case .move:
            assertionFailure("Unexpected fetched results controller section change type: \(type)")
        case .update:
            assertionFailure("Unexpected fetched results controller section change type: \(type)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Use with caution
        let (indexPath, newIndexPath): (IndexPath?, IndexPath?) = (indexPath, newIndexPath)
        guard let tableView = self.tableView else {
            return
        }
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            // Likely to break for inserted or deleted sections.
            // Must fix later.
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        case .update:
            switch (tableView.cellForRow(at: indexPath!), customizer) {
            case let (.some(cell), .some(customizer)):
                customizer.configure(cell, atIndexPath: indexPath!)
            default:
                break
            }
        }
    }
}

// Declared 'class' to allow weak references.
protocol TableViewFetchedResultsControllerCellCustomizer: class {
    func configure(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath)
}
