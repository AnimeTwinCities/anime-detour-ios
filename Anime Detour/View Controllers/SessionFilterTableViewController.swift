//
//  SessionFilterTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SessionFilterTableViewController: UITableViewController {

    enum SelectedType {
        case All
        case Named(String)
    }

    @IBInspectable var reuseIdentifier: String!

    var sessionTypes: [String]!

    /// The current selection on which to filter.
    /// Setting the selected type will update the table view.
    var selectedType: SelectedType = .All {
        didSet {
            if sessionTypes == nil {
                return
            }

            let oldIndexPath = self.indexPath(oldValue)
            if let cell = self.tableView.cellForRowAtIndexPath(oldIndexPath) {
                self.configure(cell, atIndexPath: oldIndexPath)
            }

            let newIndexPath = self.indexPath(self.selectedType)
            if let cell = self.tableView.cellForRowAtIndexPath(newIndexPath) {
                self.configure(cell, atIndexPath: newIndexPath)
            }
        }
    }

    /// The index path corresponding to a session type.
    /// Depends on `sessionTypes`. Must only be called when `sessionTypes` is non-nil.
    private func indexPath(type: SelectedType) -> NSIndexPath {
        var indexPath: NSIndexPath
        switch type {
        case .All:
            indexPath = NSIndexPath(forRow: 0, inSection: 0)
        case let .Named(name):
            if let index = find(self.sessionTypes, name) {
                indexPath = NSIndexPath(forRow: index, inSection: 1)
            } else {
                indexPath = NSIndexPath(forRow: 0, inSection: 0)
            }
        }

        return indexPath
    }

    private func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "All"
        case 1:
            cell.textLabel?.text = self.sessionTypes[indexPath.row]
        default:
            fatalError("Unexpected section number: \(indexPath.section)")
        }

        let selectedIndexPath = self.indexPath(self.selectedType)
        if indexPath == selectedIndexPath {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedType: SelectedType
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            selectedType = .All
        case let (_, row):
            selectedType = .Named(self.sessionTypes[row])
        default:
            fatalError("Unexpected combination of index path and row of selected cell")
        }

        self.selectedType = selectedType
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.sessionTypes.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.sessionTypes.count
        default:
            fatalError("Unexpected section number: \(section)")
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as UITableViewCell
        self.configure(cell, atIndexPath: indexPath)

        return cell
    }

}
