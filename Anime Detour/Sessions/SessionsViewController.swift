//
//  SessionsViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

class SessionsViewController: UICollectionViewController, FlowLayoutContaining {
    @IBInspectable private var detailSegueIdentifier: String = "sessionDetail"
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    var dataSource: (SessionDataSource & SessionStarsDataSource)? {
        didSet {
            dataSource?.sessionDataSourceDelegate = self
            dataSource?.sessionStarsDataSourceDelegate = self
        }
    }
    
    var speakerDataSource: SpeakerDataSource?
    
    var imageRepository: ImageRepository?
    
    weak var currentDetailViewController: SessionDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayoutItemWidth()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateLayoutOnTransition(toViewSize: size, with: coordinator)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, sender, segue.destination) {
        case (detailSegueIdentifier?, let cell as SessionCell, let destination as SessionDetailViewController):
            let indexPath = collectionView?.indexPath(for: cell)
            let viewModel = indexPath.map { return self.viewModel(at: $0) }
            let speakers: [SpeakerViewModel]
            if let viewModel = viewModel, let speakerDataSource = speakerDataSource {
                let speakerViewModels: [SpeakerViewModel] = viewModel.speakerIDs.flatMap { return speakerDataSource.viewModel(forSpeakerID: $0) }
                speakers = speakerViewModels
            } else {
                speakers = []
            }
            
            destination.delegate = self
            destination.imageRepository = imageRepository
            destination.viewModel = viewModel
            destination.speakers = speakers
            currentDetailViewController = destination
        default:
            break
        }
    }
    
    private func viewModel(at indexPath: IndexPath) -> SessionViewModel {
        let viewModel = dataSource!.viewModel(at: indexPath)
        return viewModel
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItems = dataSource?.numberOfItems(inSection: section) ?? 0
        return numberOfItems
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(for: indexPath) as SessionCell
        cell.viewModel = viewModel(at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueSupplementaryView(ofKind: kind, for: indexPath) as SessionHeaderCollectionReusableView
        view.timeLabel.text = dataSource!.title(forSection: indexPath.section)
        return view
    }
    
    // MARK: UIResponder
    
    override func adr_toggleStarred(forSessionID identifier: String) {
        guard let dataSource = dataSource, let sessionIndexPath = dataSource.indexPathOfSession(withSessionID: identifier) else {
            return
        }

        let existingViewModel = dataSource.viewModel(at: sessionIndexPath)
        let updatedViewModel: SessionViewModel
        if existingViewModel.isStarred {
            updatedViewModel = dataSource.unstarSession(for: existingViewModel)
        } else {
            updatedViewModel = dataSource.starSession(for: existingViewModel)
        }
        assert(updatedViewModel.sessionID == identifier)
        
        if let cell = collectionView?.cellForItem(at: sessionIndexPath) as? SessionCell {
            cell.viewModel = updatedViewModel
        }
        
        if let detailVC = currentDetailViewController, detailVC.viewModel?.sessionID == identifier {
            detailVC.viewModel = updatedViewModel
        }
    }
}

private extension SessionsViewController {
    func toggleStarred(for viewModel: SessionViewModel) {
        guard let dataSource = dataSource else {
            return
        }
        
        let identifier = viewModel.sessionID
        
        let updatedViewModel: SessionViewModel
        if viewModel.isStarred {
            updatedViewModel = dataSource.unstarSession(for: viewModel)
        } else {
            updatedViewModel = dataSource.starSession(for: viewModel)
        }
        assert(updatedViewModel.sessionID == identifier)
        
        if let sessionIndexPath = dataSource.indexPathOfSession(withSessionID: identifier), let cell = collectionView?.cellForItem(at: sessionIndexPath) as? SessionCell {
            cell.viewModel = updatedViewModel
        }
        
        if let detailVC = currentDetailViewController, detailVC.viewModel?.sessionID == viewModel.sessionID {
            detailVC.viewModel = updatedViewModel
        }
    }
}

extension SessionsViewController: SessionDataSourceDelegate {
    func sessionDataSourceDidUpdate() {
        // TODO: animate updates
        collectionView?.reloadData()
    }
}

extension SessionsViewController: SessionStarsDataSourceDelegate {
    func sessionStarsDidUpdate(dataSource: SessionStarsDataSource) {
        // TODO: animate updates
        collectionView?.reloadData()
    }
}

extension SessionsViewController: SessionDetailViewControllerDelegate {
    func addSessionToSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController) {
        assert(!viewModel.isStarred, "Shouldn't be able to add a session if it is already starred.")
        toggleStarred(for: viewModel)
    }
    
    func removeSessionFromSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController) {
        assert(viewModel.isStarred, "Shouldn't be able to remove a session if it is not yet starred.")
        toggleStarred(for: viewModel)
    }
}
