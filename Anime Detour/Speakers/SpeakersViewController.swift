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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFlowLayoutItemWidth(viewSize: view?.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateLayoutOnTransition(toViewSize: size, with: coordinator)
    }
    
    func updateFlowLayoutItemWidth(viewSize size: CGSize?) {
        guard let flowLayout = flowLayout, let size = size else {
            return
        }
        
        let height = flowLayout.itemSize.height
        // 384 == 768 / 2, giving us more than one column only when our view is 768 wide or wider.
        let numberOfColumns = floor(size.width / 384)
        let impreciseWidth = size.width / numberOfColumns
        let width = floor(impreciseWidth)
        let cellSize = CGSize(width: width, height: height)
        flowLayout.itemSize = cellSize
        flowLayout.invalidateLayout()
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
