//
//  GuestCollectionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

import AnimeDetourAPI

/**
Collection view controller displaying `Guest`s. Requires the collection view to use a `UICollectionViewFlowLayout`.
*/
class GuestCollectionViewController: UICollectionViewController, CollectionViewFetchedResultsControllerCellCustomizer {

    lazy var imageSession: NSURLSession = NSURLSession.sharedSession()

    /// Detail segue identifier
    @IBInspectable var detailIdentifier: String!

    /// Cell reuse identifier
    @IBInspectable var reuseIdentifier: String!

    /// Section header reuse identifier
    @IBInspectable var headerIdentifier: String!

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

    private lazy var managedObjectContext = CoreDataController.sharedInstance.managedObjectContext

    private lazy var fetchedResultsControllerDelegate = CollectionViewFetchedResultsControllerDelegate()

    // MARK: Collection view sizing

    private var lastDisplayedTraitCollection: UITraitCollection!

    // MARK: View controller

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchedResultsControllerDelegate.collectionView = self.collectionView
        self.fetchedResultsControllerDelegate.customizer = self

        let frc = self.fetchedResultsController
        frc.delegate = self.fetchedResultsControllerDelegate

        var error: NSError?
        if !frc.performFetch(&error) {
            NSLog("Error fetching guests: \(error!)")
        }

        self.setFlowLayoutCellSizes(self.collectionView!)
        self.lastDisplayedTraitCollection = self.traitCollection
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if self.traitCollection != self.lastDisplayedTraitCollection {
            self.setFlowLayoutCellSizes(self.collectionView!)
            self.lastDisplayedTraitCollection = self.traitCollection
        }
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        // Update sizes in `willAnimateRotationToInterfaceOrientation...` so the collection view's
        // frame is already updated.
        self.setFlowLayoutCellSizes(self.collectionView!)
        self.lastDisplayedTraitCollection = self.traitCollection
    }

    private func guest(indexPath: NSIndexPath) -> Guest {
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as Guest
    }

    /// Update the sizes of our collection view cells based on the view's trait collection.
    private func setFlowLayoutCellSizes(collectionView: UICollectionView) {
        let traitCollection = collectionView.traitCollection
        let viewWidth = collectionView.frame.width
        let layout = collectionView.collectionViewLayout as UICollectionViewFlowLayout
        var itemSize = layout.itemSize

        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            itemSize.width = viewWidth
        } else {
            // Assume .Regular
            let minWidth: CGFloat = 280
            let cellsPerRow = floor(viewWidth / minWidth)
            let widthPerCell = floor(viewWidth / cellsPerRow) // ensure cell widths are integral
            itemSize.width = widthPerCell
        }

        layout.itemSize = itemSize
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as UICollectionViewCell
        self.configure(cell, atIndexPath: indexPath)
        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: self.headerIdentifier, forIndexPath: indexPath) as TextHeaderCollectionReusableView

        // Assume that `indexPath` is for item 0 in whatever section to which the header belongs
        let anyGuest = self.fetchedResultsController.objectAtIndexPath(indexPath) as Guest
        header.titleLabel.text = anyGuest.category

        return header
    }

    // MARK: - Collection view cell customizer

    func configure(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let cell = cell as GuestCollectionViewCell

        let guest = self.guest(indexPath)
        let viewModel = GuestViewModel(guest: guest, imageSession: self.imageSession)
        cell.viewModel = viewModel
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case .Some(self.detailIdentifier):
            let cell = sender as GuestCollectionViewCell
            let guestViewModel = cell.viewModel
            let guestVC = segue.destinationViewController as GuestDetailTableViewController
            guestVC.guestViewModel = guestViewModel
        default:
            fatalError("Unexpected segue encountered.")
        }
    }

}
