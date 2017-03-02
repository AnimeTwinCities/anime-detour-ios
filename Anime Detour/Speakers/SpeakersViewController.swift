//
//  SpeakersCollectionViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

class SpeakersViewController: UICollectionViewController, FlowLayoutContaining {
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    var speakerDataSource: SpeakerDataSource?
    
    var imageRepository: ImageRepository?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayoutItemWidth()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateLayoutOnTransition(toViewSize: size, with: coordinator)
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return speakerDataSource?.numberOfItems(inSection: section) ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(for: indexPath) as SpeakerCell
        let viewModel = speakerDataSource!.viewModel(at: indexPath)
        cell.viewModel = viewModel
        let image: UIImage?
        let faceRect: CGRect?
        if let imageRepository = imageRepository, let url = viewModel.imageURL {
            let (maybeImage, maybeFaceRect, _) = imageRepository.image(at: url, completion: { [weak collectionView] (maybeImage, _) in
                guard let _ = maybeImage else {
                    return
                }
                
                DispatchQueue.main.async {
                    collectionView?.reloadItems(at: [indexPath])
                }
            })
            faceRect = maybeFaceRect
            image = maybeImage ?? .speakerPlaceholder
        } else {
            faceRect = nil
            image = .speakerPlaceholder
        }
        cell.faceRect = faceRect
        cell.image = image
        return cell
    }

    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch (segue.destination, sender) {
        case (let detailVC as SpeakerDetailViewController, let cell as SpeakerCell):
            guard let viewModel = cell.viewModel else {
                assertionFailure("No view model found on cell that triggered a detail segue. Was the cell set up correctly?")
                return
            }
            
            detailVC.viewModel = viewModel
            detailVC.imageRepository = imageRepository
        default:
            NSLog("Unexpected segue: \(segue)")
        }
    }
}

extension SpeakersViewController: SpeakerDataSourceDelegate {
    func speakerDataSourceDidUpdate() {
        collectionView?.reloadData()
    }
}
