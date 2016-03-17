//
//  SessionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 UIScrollView so it can adjust the photo during scrolling.
 */
class SessionView: UIScrollView, SessionViewModelDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var panelistsLabel: UILabel!
    
    @IBOutlet var panelistsView: UIView!
    
    @IBOutlet var imageHeaderView: ImageHeaderView!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var bookmarkButton: UIButton!
    
    /// Value for the image view height constraint, if an image is available.
    @IBInspectable var imageHeight: CGFloat = 180

    private var image: UIImage? {
        didSet {
            imageView.image = image
            
            switch image {
            case _?:
                imageHeaderView.hidden = false
            default:
                imageHeaderView.hidden = true
            }
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
            categoryLabel.text = viewModel?.category
            if let panelists = viewModel?.panelists where panelists.characters.count > 0 {
                panelistsLabel.text = panelists
            } else {
                panelistsView.hidden = true
            }

            bookmarkButton.setImage(viewModel?.bookmarkImage, forState: .Normal)
            bookmarkButton.accessibilityLabel = viewModel?.bookmarkAccessibilityLabel
            
            viewModel?.image({ [weak self] (image, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    switch image {
                    case let .Some(image):
                        self?.image = image
                    default:
                        self?.imageHeaderView.hidden = true
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