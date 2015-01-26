//
//  GuestTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import CoreData
import UIKit

import AnimeDetourAPI

class GuestTableViewController: UITableViewController {

    @IBInspectable var detailIdentifier: String!
    @IBInspectable var reuseIdentifier: String!

    /// Lazily created FRC. To use, first perform a fetch on it.
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = self.managedObjectContext
        let entity = NSEntityDescription.entityForName(Guest.entityName, inManagedObjectContext: moc)
        let sort = NSSortDescriptor(key: "firstName", ascending: true)
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "category", cacheName: nil)
        return frc
    }()

    private lazy var managedObjectContext = CoreDataController.sharedInstance.managedObjectContext!

    private lazy var fetchedResultsControllerDelegate = TableViewFetchedResultsControllerDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchedResultsControllerDelegate.tableView = self.tableView

        let frc = self.fetchedResultsController
        frc.delegate = self.fetchedResultsControllerDelegate

        var error: NSError?
        if !frc.performFetch(&error) {
            NSLog("Error fetching guests: \(error!)")
        }
    }

    private func guest(indexPath: NSIndexPath) -> Guest {
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as Guest
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as UITableViewCell

        let guest = self.guest(indexPath)
        let viewModel = GuestViewModel(guest: guest)
        cell.textLabel?.text = viewModel.name

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(self.detailIdentifier):
            let cell = sender as UITableViewCell
            let guest = self.guest(self.tableView.indexPathForCell(cell)!)
            let guestVC = segue.destinationViewController as GuestViewController
            guestVC.guest = guest
        default:
            fatalError("Unexpected segue encountered.")
        }
    }

}
