//
//  SessionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

class SessionView: UIScrollView, SessionViewModelDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var typesLabel: UILabel!
    @IBOutlet var panelistsLabel: UILabel!
    
    @IBOutlet var imageHeaderView: ImageHeaderView!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet var imageHeaderViewHeightConstraint: NSLayoutConstraint!
    
    /// Value for the image view height constraint, if an image is available.
    @IBInspectable var imageHeight: CGFloat = 180

    private var image: UIImage? {
        didSet {
            imageView.image = image
            
            switch image {
            case _?:
                imageHeaderViewHeightConstraint.constant = imageHeight
            default:
                imageHeaderViewHeightConstraint.constant = 0
            }
            
            layoutIfNeeded()
        }
    }

    @IBAction func bookmarkButtonTapped(sender: AnyObject) {
        viewModel?.toggleBookmarked()
    }
    
    var viewModel: SessionViewModel? {
        didSet {
            nameLabel.text = viewModel?.name
            timeLabel.text = viewModel?.dateAndTime
            locationLabel.text = viewModel?.location
            descriptionLabel.text = viewModel?.sessionDescription
            typesLabel.text = viewModel?.types
            panelistsLabel.text = ""

            bookmarkButton.setImage(viewModel?.bookmarkImage, forState: .Normal)
            bookmarkButton.accessibilityLabel = viewModel?.bookmarkAccessibilityLabel
            
            viewModel?.image({ [weak self] (image, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    switch image {
                    case let .Some(image):
                        self?.image = image
                    default:
                        self?.imageHeaderViewHeightConstraint.constant = 0
                    }
                })
            })
        }
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String) {
        bookmarkButton.setImage(bookmarkImage, forState: .Normal)
        bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}