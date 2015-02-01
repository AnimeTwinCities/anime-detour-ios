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

class GuestTableViewController: UITableViewController, TableViewFetchedResultsControllerCellCustomizer {

    lazy var imageSession: NSURLSession = NSURLSession.sharedSession()

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
        self.fetchedResultsControllerDelegate.customizer = self

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
        self.configure(cell, atIndexPath: indexPath)
        return cell
    }

    // MARK: - Table view cell customizer

    func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let cell = cell as GuestTableViewCell

        let guest = self.guest(indexPath)
        let viewModel = GuestViewModel(guest: guest, imageSession: self.imageSession)
        cell.viewModel = viewModel
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(self.detailIdentifier):
            let cell = sender as GuestTableViewCell
            let guestViewModel = cell.viewModel
            let guestVC = segue.destinationViewController as GuestDetailTableViewController
            guestVC.guestViewModel = guestViewModel
        default:
            fatalError("Unexpected segue encountered.")
        }
    }

}
