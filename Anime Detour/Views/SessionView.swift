//
//  SessionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

class SessionView: UIView, SessionViewModelDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    @IBOutlet var imageView: UIImageView!

    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
    
    /// Value for the image view height constraint, if an image is available.
    @IBInspectable var imageHeight: CGFloat = 180

    private var image: UIImage? {
        didSet {
            self.imageView.image = self.image
            
            switch image {
            case let .Some(image):
                self.imageViewHeightConstraint.constant = self.imageHeight
            default:
                self.imageViewHeightConstraint.constant = 0
            }
            
            self.layoutIfNeeded()
        }
    }

    @IBAction func bookmarkButtonTapped(sender: AnyObject) {
        self.viewModel?.toggleBookmarked()
    }
    
    var viewModel: SessionViewModel? {
        didSet {
            let viewModel = self.viewModel
            self.nameLabel.text = viewModel?.name
            self.timeLabel.text = viewModel?.dateAndTime
            self.locationLabel.text = viewModel?.location
            self.descriptionLabel.text = viewModel?.sessionDescription

            self.bookmarkButton.setImage(viewModel?.bookmarkImage, forState: .Normal)
            self.bookmarkButton.accessibilityLabel = viewModel?.bookmarkAccessibilityLabel
            
            viewModel?.image({ [weak self] (image, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    switch image {
                    case let .Some(image):
                        self?.image = image
                    default:
                        self?.imageViewHeightConstraint.constant = 0
                    }
                })
            })
        }
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String) {
        self.bookmarkButton.setImage(bookmarkImage, forState: .Normal)
        self.bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}