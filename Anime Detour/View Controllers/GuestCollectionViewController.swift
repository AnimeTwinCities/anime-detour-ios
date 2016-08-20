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

    lazy var imageSession: URLSession = URLSession.shared
    
    // MARK: Segues

    /// Detail segue identifier
    @IBInspectable var detailIdentifier: String!

    /// Cell reuse identifier
    @IBInspectable var reuseIdentifier: String!

    /// Section header reuse identifier
    @IBInspectable var headerIdentifier: String!
    
    // MARK: Handoff
    
    fileprivate var handoffGuestID: String?

    // MARK: Core Data
    
    /// Lazily created FRC. To use, first perform a fetch on it.
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Guest> = { () -> NSFetchedResultsController<Guest> in
        let moc = self.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: Guest.entityName, in: moc)
        let sort = NSSortDescriptor(key: Guest.Keys.firstName.rawValue, ascending: true)
        let fetchRequest = NSFetchRequest<Guest>()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [sort]
        let frc = NSFetchedResultsController<Guest>(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: Guest.Keys.category.rawValue, cacheName: nil)
        return frc
    }()

    fileprivate lazy var managedObjectContext = CoreDataController.sharedInstance.managedObjectContext

    fileprivate lazy var fetchedResultsControllerDelegate = CollectionViewFetchedResultsControllerDelegate()
    
    // MARK: Face Detection
    
    fileprivate let faceDetector = ImageFaceDetector()
    
    // The detail view, so we can update it after we get a hi res photo or face.
    fileprivate weak var detailViewController: GuestDetailViewController?

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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.view.setNeedsUpdateConstraints()
            }, completion: nil)
    }
    
    // MARK: - UIResponder
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard let guestID = activity.userInfo?[GuestDetailViewController.guestActivityGuestIDKey] as? String else {
            return
        }
        
        let fetchRequest = NSFetchRequest<Guest>(entityName: Guest.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Guest.Keys.guestID.rawValue, guestID)
        let count = try? fetchedResultsController.managedObjectContext.count(for: fetchRequest)
        guard count == 1 else {
            // don't do anything, since we don't have the guest for the ID that we received
            return
        }
        
        handoffGuestID = guestID
        performSegue(withIdentifier: detailIdentifier, sender: self)
    }
    
    // MARK: Data Display

    fileprivate func guestAt(_ indexPath: IndexPath) -> Guest {
        return fetchedResultsController.object(at: indexPath)
    }

    /// Update the sizes of our collection view cells based on the view's trait collection.
    fileprivate func setFlowLayoutCellSizes(_ collectionView: UICollectionView) {
        let traitCollection = collectionView.traitCollection
        let viewWidth = collectionView.frame.width
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        var itemSize = layout.itemSize

        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact {
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

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, for: indexPath) as! TextHeaderCollectionReusableView

        // Assume that `indexPath` is for item 0 in whatever section to which the header belongs
        let info = fetchedResultsController.sections?[(indexPath as NSIndexPath).section]
        header.titleLabel.text = info?.name

        return header
    }

    // MARK: - Collection view cell customizer

    func configure(_ cell: UICollectionViewCell, atIndexPath indexPath: IndexPath) {
        let cell = cell as! GuestCollectionViewCell

        let guest = guestAt(indexPath)
        let viewModel =  GuestViewModel(guest: guest, imageSession: imageSession)
        viewModel.delegate = self
        cell.viewModel = viewModel

        // lol separation of concerns
        // Update the detail view controller's view model if that's the one
        // we're configuring.
        guard let detailVC = detailViewController , detailVC.guestViewModel?.guestObjectID == guest.objectID else {
            return
        }
        
        detailVC.guestViewModel = viewModel
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier) {
        case detailIdentifier?:
            let viewModel: GuestViewModel
            switch sender {
            case let cell as GuestCollectionViewCell:
                viewModel = cell.viewModel!
            case self as GuestCollectionViewController:
                let guestID = handoffGuestID!
                let fetchRequest = NSFetchRequest<Guest>(entityName: Guest.entityName)
                fetchRequest.predicate = NSPredicate(format: "%K == %@", Guest.Keys.guestID.rawValue, guestID)
                fetchRequest.fetchLimit = 1
                let results = try! managedObjectContext.fetch(fetchRequest)
                let guest = results.first!
                
                viewModel = GuestViewModel(guest: guest, imageSession: imageSession)
                viewModel.delegate = self
            default:
                preconditionFailure("Unexpected segue sender.")
            }
            
            let guestVC = segue.destination as! GuestDetailViewController
            guestVC.guestViewModel = viewModel
            
            detailViewController = guestVC
        default:
            fatalError("Unexpected segue encountered.")
        }
    }

}

private extension GuestCollectionViewController {
    func findFaceFor(_ photo: UIImage, forGuestWithID guestObjectID: NSManagedObjectID, inContext context: NSManagedObjectContext) {
        faceDetector.findFace(photo) { [weak self, weak context] face in
            // Though we don't need `self`, skip doing any work if `self` no longer exists.
            guard let _ = self, let context = context else { return }
            context.perform({ () -> Void in
                guard let guest = context.object(with: guestObjectID) as? Guest else {
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

    func didDownloadPhoto(_ viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        DispatchQueue.main.async { [weak self, guestObjectID = viewModel.guestObjectID] () -> Void in
            guard let strongSelf = self else {
                return
            }
            
            // Skip face logic for low-res photos
            guard hiRes else { return }
            
            if let guest = strongSelf.managedObjectContext.object(with: guestObjectID) as? Guest, let faceLocation = guest.hiResPhotoFaceBoundsRect {
                viewModel.photoFaceLocation = faceLocation
            } else {
                strongSelf.findFaceFor(photo, forGuestWithID: guestObjectID, inContext: strongSelf.managedObjectContext)
            }
        }
    }

    func didFailDownloadingPhoto(_ viewModel: GuestViewModel, error: NSError) {
        // empty
    }
}
