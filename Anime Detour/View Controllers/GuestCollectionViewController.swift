//
//  GuestCollectionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

import AnimeDetourDataModel

/**
 Collection view controller displaying `Guest`s. Requires the collection view to use a `UICollectionViewFlowLayout`.
 */
class GuestCollectionViewController: UICollectionViewController, CollectionViewFetchedResultsControllerCellCustomizer {
    // MARK: Images

    lazy var imageSession: NSURLSession = NSURLSession.sharedSession()
    
    // MARK: Segues

    /// Detail segue identifier
    @IBInspectable var detailIdentifier: String!

    /// Cell reuse identifier
    @IBInspectable var reuseIdentifier: String!

    /// Section header reuse identifier
    @IBInspectable var headerIdentifier: String!
    
    // MARK: Handoff
    
    private var handoffGuestID: String?

    // MARK: Core Data
    
    /// Lazily created FRC. To use, first perform a fetch on it.
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let moc = self.managedObjectContext
        let entity = NSEntityDescription.entityForName(Guest.entityName, inManagedObjectContext: moc)
        let sort = NSSortDescriptor(key: Guest.Keys.firstName.rawValue, ascending: true)
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: Guest.Keys.category.rawValue, cacheName: nil)
        return frc
    }()

    private lazy var managedObjectContext = CoreDataController.sharedInstance.managedObjectContext

    private lazy var fetchedResultsControllerDelegate = CollectionViewFetchedResultsControllerDelegate()
    
    // MARK: Face Detection
    
    private let faceDetector = ImageFaceDetector()
    
    // The detail view, so we can update it after we get a hi res photo or face.
    private weak var detailViewController: GuestDetailTableViewController?

    // MARK: View controller

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchedResultsControllerDelegate.collectionView = collectionView
        fetchedResultsControllerDelegate.customizer = self

        let frc = fetchedResultsController
        frc.delegate = fetchedResultsControllerDelegate

        do {
            try frc.performFetch()
        } catch {
            let error = error as NSError
            NSLog("Error fetching guests: \(error)")
        }

        setFlowLayoutCellSizes(collectionView!)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        self.setFlowLayoutCellSizes(self.collectionView!)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ _ in
            self.view.setNeedsUpdateConstraints()
            }, completion: nil)
    }
    
    // MARK: - UIResponder
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        guard let guestID = activity.userInfo?[GuestDetailTableViewController.guestActivityGuestIDKey] as? String else {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: Guest.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Guest.Keys.guestID.rawValue, guestID)
        let count = fetchedResultsController.managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        guard count == 1 else {
            // don't do anything, since we don't have the guest for the ID that we received
            return
        }
        
        handoffGuestID = guestID
        performSegueWithIdentifier(detailIdentifier, sender: self)
    }
    
    // MARK: Data Display

    private func guestAt(indexPath: NSIndexPath) -> Guest {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! Guest
    }

    /// Update the sizes of our collection view cells based on the view's trait collection.
    private func setFlowLayoutCellSizes(collectionView: UICollectionView) {
        let traitCollection = collectionView.traitCollection
        let viewWidth = collectionView.frame.width
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
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
        return fetchedResultsController.sections?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, forIndexPath: indexPath) as! TextHeaderCollectionReusableView

        // Assume that `indexPath` is for item 0 in whatever section to which the header belongs
        let anyGuest = fetchedResultsController.objectAtIndexPath(indexPath) as! Guest
        header.titleLabel.text = anyGuest.category

        return header
    }

    // MARK: - Collection view cell customizer

    func configure(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let cell = cell as! GuestCollectionViewCell

        let guest = guestAt(indexPath)
        let viewModel =  GuestViewModel(guest: guest, imageSession: imageSession)
        viewModel.delegate = self
        cell.viewModel = viewModel

        // lol separation of concerns
        // Update the detail view controller's view model if that's the one
        // we're configuring.
        guard let detailVC = detailViewController where detailVC.guestViewModel?.guestObjectID == guest.objectID else {
            return
        }
        
        detailVC.guestViewModel = viewModel
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier) {
        case detailIdentifier?:
            let viewModel: GuestViewModel
            switch sender {
            case let cell as GuestCollectionViewCell:
                viewModel = cell.viewModel!
            case self as GuestCollectionViewController:
                let guestID = handoffGuestID!
                let fetchRequest = NSFetchRequest(entityName: Guest.entityName)
                fetchRequest.predicate = NSPredicate(format: "%K == %@", Guest.Keys.guestID.rawValue, guestID)
                fetchRequest.fetchLimit = 1
                let results = try? managedObjectContext.executeFetchRequest(fetchRequest)
                let guest = results?.first as! Guest
                
                viewModel = GuestViewModel(guest: guest, imageSession: imageSession)
                viewModel.delegate = self
            default:
                preconditionFailure("Unexpected segue sender.")
            }
            
            let guestVC = segue.destinationViewController as! GuestDetailTableViewController
            guestVC.guestViewModel = viewModel
            
            detailViewController = guestVC
        default:
            fatalError("Unexpected segue encountered.")
        }
    }

}

private extension GuestCollectionViewController {
    func findFaceFor(photo: UIImage, forGuestWithID guestObjectID: NSManagedObjectID, inContext context: NSManagedObjectContext) {
        faceDetector.findFace(photo) { [weak self, weak context] face in
            // Though we don't need `self`, skip doing any work if `self` no longer exists.
            guard let _ = self, context = context else { return }
            context.performBlock({ () -> Void in
                guard let guest = context.objectWithID(guestObjectID) as? Guest else {
                    return
                }
                
                guest.hiResPhotoFaceBoundsRect = face
                do {
                    try context.save()
                } catch {
                    NSLog("Error saving after finding a face in a guest image: %@", error as NSError)
                }
            })
        }
    }
}

extension GuestCollectionViewController: GuestViewModelDelegate {
    // MARK: - Guest View Model Delegate

    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        dispatch_async(dispatch_get_main_queue()) { [weak self, guestObjectID = viewModel.guestObjectID] () -> Void in
            guard let strongSelf = self else {
                return
            }
            
            // Skip face logic for low-res photos
            guard hiRes else { return }
            
            if let guest = strongSelf.managedObjectContext.objectWithID(guestObjectID) as? Guest, faceLocation = guest.hiResPhotoFaceBoundsRect {
                viewModel.photoFaceLocation = faceLocation
            } else {
                strongSelf.findFaceFor(photo, forGuestWithID: guestObjectID, inContext: strongSelf.managedObjectContext)
            }
        }
    }

    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError) {
        // empty
    }
}
