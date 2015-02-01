//
//  GuestView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestView: UIView, GuestViewModelDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var bioView: UITextView!
    @IBOutlet var imageZeroHeightConstraint: NSLayoutConstraint!

    var viewModel: GuestViewModel! {
        didSet {
            self.viewModel.delegate = self

            let photo = self.viewModel.hiResPhoto(true, lowResPhotoPlaceholder: true) ?? self.viewModel.photo
            self.imageView.image = photo

            self.imageZeroHeightConstraint.priority = photo == nil ? 1000 : 1
            self.nameLabel.text = self.viewModel.name
            self.bioView.attributedText = self.viewModel.htmlBio
        }
    }

    // MARK: - Guest View Model Delegate

    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        self.imageView.image = photo

        self.imageZeroHeightConstraint.priority = 1
    }

    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError) {
        // empty
    }
}
