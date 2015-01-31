//
//  GuestTableViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/29/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestTableViewCell: UITableViewCell, GuestViewModelDelegate {

    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!

    var viewModel: GuestViewModel? {
        didSet {
            if let viewModel = self.viewModel {
                self.nameLabel.text = viewModel.name
                self.categoryLabel.text = viewModel.category

                let photo = viewModel.photo(true)
                self.photoImageView.image = photo
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.viewModel = nil
    }

    // MARK: - Guest View Model Delegate

    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        // Asssume that if the view model downloaded a photo, that is the only property
        // on it that changed.
        if self.viewModel === viewModel {
            self.photoImageView.image = photo
        }
    }

    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError) {
        // empty
    }
}
