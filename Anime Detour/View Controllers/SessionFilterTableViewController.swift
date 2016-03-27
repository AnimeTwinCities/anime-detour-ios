//
//  SessionFilterTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

import AnimeDetourDataModel

class SessionFilterTableViewController: UITableViewController {
    
    @IBInspectable var allReuseIdentifier: String!
    @IBInspectable var categoryReuseIdentifier: String!

    var sessionTypes: [Session.Category]!

    /// The current selection on which to filter.
    /// Setting the selected type will update the table view.
    var selectedType: SelectedSessionCategory = .All {
        didSet {
            if sessionTypes == nil {
                return
            }

            let oldIndexPath = indexPath(oldValue)
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) {
                configure(cell, atIndexPath: oldIndexPath)
            }

            let newIndexPath = indexPath(selectedType)
            if let cell = tableView.cellForRowAtIndexPath(newIndexPath) {
                configure(cell, atIndexPath: newIndexPath)
            }
        }
    }

    /// The index path corresponding to a session type.
    /// Depends on `sessionTypes`. Must only be called when `sessionTypes` is non-nil.
    private func indexPath(type: SelectedSessionCategory) -> NSIndexPath {
        var indexPath: NSIndexPath
        switch type {
        case .All:
            indexPath = NSIndexPath(forRow: 0, inSection: 0)
        case let .Category(category):
            if let index = self.sessionTypes.indexOf(category) {
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
            let category = self.sessionTypes[indexPath.row]
            let categoryCell = cell as! FilterCategoryTableViewCell
            let color = category.color
            
            let label = categoryCell.categoryLabel
            label?.text = category.name
            label?.textColor = color
            
            let layer = label?.layer
            layer?.borderColor = color?.CGColor
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
        var selectedType: SelectedSessionCategory
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            selectedType = .All
        case let (_, row):
            selectedType = .Category(self.sessionTypes[row])
        }

        self.selectedType = selectedType
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if sessionTypes.count > 0 {
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
            return sessionTypes.count
        default:
            fatalError("Unexpected section number: \(section)")
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = indexPath.section == 0 ? allReuseIdentifier : categoryReuseIdentifier
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as UITableViewCell
        configure(cell, atIndexPath: indexPath)

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Categories"
        default:
            fatalError("Unexpected section number: \(section)")
        }
    }

}

class FilterCategoryTableViewCell: UITableViewCell {
    @IBOutlet var categoryLabel: UILabel?
}
