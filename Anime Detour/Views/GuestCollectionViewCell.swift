//
//  GuestCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestCollectionViewCell: UICollectionViewCell, GuestViewModelDelegate {

    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    var viewModel: GuestViewModel? {
        didSet {
            guard let viewModel = self.viewModel else {
                return
            }

            viewModel.delegate = self
            self.nameLabel.text = viewModel.name
            
            let photo = viewModel.photo(true)
            self.photoImageView.image = photo
        }
    }

    override var highlighted: Bool {
        didSet {
            let backgroundColor: UIColor

            if self.highlighted {
                backgroundColor = UIColor(white: 0.8, alpha: 1)
            } else {
                backgroundColor = UIColor.clearColor()
            }

            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.contentView.backgroundColor = backgroundColor
            })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Without setting an `autoresizingMask`, the content view has a
        // mysterious 50pt width constraint that we don't want.
        // So just set it to autoresize.
        self.contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true

        let imageLayer = self.photoImageView.layer
        imageLayer.borderColor = UIColor.lightGrayColor().CGColor
        imageLayer.cornerRadius = self.photoImageView.frame.width / 2
        imageLayer.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.viewModel = nil
    }
    
    override func didMoveToWindow() {
        let imageLayer = self.photoImageView.layer
        imageLayer.borderWidth = 1 / (self.window?.screen.scale ?? 1)
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
