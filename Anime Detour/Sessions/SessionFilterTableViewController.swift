//
//  SessionFilterTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SessionFilterTableViewController: UITableViewController {
    
    @IBInspectable var allReuseIdentifier: String!
    @IBInspectable var categoryReuseIdentifier: String!

    var sessionTypes: [SessionViewModel.Category]!

    /// The current selection on which to filter.
    /// Setting the selected type will update the table view.
    var selectedType: SelectedSessionCategory = .all {
        didSet {
            if sessionTypes == nil {
                return
            }

            let oldIndexPath = indexPath(oldValue)
            if let cell = tableView.cellForRow(at: oldIndexPath) {
                configure(cell, atIndexPath: oldIndexPath)
            }

            let newIndexPath = indexPath(selectedType)
            if let cell = tableView.cellForRow(at: newIndexPath) {
                configure(cell, atIndexPath: newIndexPath)
            }
        }
    }

    /// The index path corresponding to a session type.
    /// Depends on `sessionTypes`. Must only be called when `sessionTypes` is non-nil.
    fileprivate func indexPath(_ type: SelectedSessionCategory) -> IndexPath {
        var indexPath: IndexPath
        switch type {
        case .all:
            indexPath = IndexPath(row: 0, section: 0)
        case let .category(category):
            if let index = self.sessionTypes.index(of: category) {
                indexPath = IndexPath(row: index, section: 1)
            } else {
                indexPath = IndexPath(row: 0, section: 0)
            }
        }

        return indexPath
    }

    fileprivate func configure(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            cell.textLabel?.text = "All"
        case 1:
            let category = self.sessionTypes[(indexPath as NSIndexPath).row]
            let categoryCell = cell as! FilterCategoryTableViewCell
            let color = category.color
            
            let label = categoryCell.categoryLabel
            label?.text = category.name
            label?.textColor = color
            
            let layer = label?.layer
            layer?.borderColor = color?.cgColor
        default:
            fatalError("Unexpected section number: \((indexPath as NSIndexPath).section)")
        }

        let selectedIndexPath = self.indexPath(self.selectedType)
        if indexPath == selectedIndexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedType: SelectedSessionCategory
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0, _):
            selectedType = .all
        case let (_, row):
            selectedType = .category(self.sessionTypes[row])
        }

        self.selectedType = selectedType
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if sessionTypes.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return sessionTypes.count
        default:
            fatalError("Unexpected section number: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = (indexPath as NSIndexPath).section == 0 ? allReuseIdentifier : categoryReuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier!, for: indexPath) as UITableViewCell
        configure(cell, atIndexPath: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
