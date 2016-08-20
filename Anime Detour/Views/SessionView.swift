//
//  SessionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

@objc protocol SessionViewDelegate {
    func didTapBookmarkButton()
}

/**
 UIScrollView so it can adjust the photo during scrolling.
 */
class SessionView: UIScrollView, AgeRequirementDisplayingView, SessionViewModelDelegate {
    /// The view which contains all of our subviews that actually have content,
    /// since we're a scroll view.
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var ageRequirementLabel: InsettableLabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var categoryLabel: InsettableLabel!
    @IBOutlet var panelistsLabel: UILabel!
    @IBOutlet var ageRequirementInfoLabel: UILabel!
    
    /// The view displaying the session's description and any associated views.
    @IBOutlet var descriptionView: UIView!
    /// The view displaying the session's panelists and any associated views.
    @IBOutlet var panelistsView: UIView!
    /// The views displaying the session's age requirement info text and any associated views.
    /// They may not all be contained in one stack view, so use a collection.
    @IBOutlet var ageRequirementViews: [UIView]!
    
    @IBOutlet var imageHeaderView: ImageHeaderView!

    @IBOutlet var bookmarkButton: UIButton!
    
    @IBOutlet weak var sessionDelegate: SessionViewDelegate?
    
    fileprivate var ageRequirementDescriptionText: String?
    
    fileprivate var originalCategoryLabelColor: UIColor = UIColor.black

    fileprivate var image: UIImage? {
        didSet {
            imageHeaderView.image = image
            
            switch image {
            case _?:
                imageHeaderView.isHidden = false
            default:
                imageHeaderView.isHidden = true
            }
        }
    }
    
    var viewModel: SessionViewModel? {
        didSet {
            nameLabel.text = viewModel?.name
            timeLabel.text = viewModel?.dateAndTime
            
            if let viewModel = viewModel {
                showAgeRequirementOrHideLabel(forViewModel: viewModel)
                showAgeRequirementInfoOrHideViews(viewModel)
            }
            
            locationLabel.text = viewModel?.location
            if let sessionDescription = viewModel?.sessionDescription , !sessionDescription.isEmpty {
                descriptionView.isHidden = false
                descriptionLabel.text = sessionDescription
            } else {
                descriptionView.isHidden = true
            }
            categoryLabel.text = viewModel?.category
            let categoryColor = viewModel?.categoryColor ?? originalCategoryLabelColor
            categoryLabel.textColor = categoryColor
            let categoryLabelLayer = categoryLabel.layer
            categoryLabelLayer.borderColor = categoryColor.cgColor
            
            if let panelists = viewModel?.panelists , !panelists.isEmpty {
                panelistsView.isHidden = false
                panelistsLabel.text = panelists
            } else {
                panelistsView.isHidden = true
            }

            bookmarkButton.setImage(viewModel?.bookmarkImage, for: UIControlState())
            bookmarkButton.accessibilityLabel = viewModel?.bookmarkAccessibilityLabel
            
            if case true? = viewModel?.hasImage {
                imageHeaderView.isHidden = false
                imageHeaderView.image = nil
            } else {
                imageHeaderView.isHidden = true
            }
            
            viewModel?.image({ [weak self] (image, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    switch image {
                    case let .some(image):
                        self?.image = image
                    default:
                        self?.imageHeaderView.isHidden = true
                    }
                })
            })
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ageRequirementDescriptionText = ageRequirementInfoLabel.text
        originalCategoryLabelColor = categoryLabel.textColor
    }
    
    @IBAction func bookmarkButtonTapped(_ sender: AnyObject) {
        sessionDelegate?.didTapBookmarkButton()
    }
    
    fileprivate func showAgeRequirementInfoOrHideViews(_ viewModel: SessionViewModel) {
        let ageRequired: Int?
        if viewModel.is18Plus {
            ageRequired = 18
        } else if viewModel.is21Plus {
            ageRequired = 21
        } else {
            ageRequired = nil
        }
        
        if let ageRequired = ageRequired, let ageRequirementDescriptionText = ageRequirementDescriptionText {
            ageRequirementInfoLabel.text = String(format: ageRequirementDescriptionText, ageRequired)
            for view in ageRequirementViews {
                view.isHidden = false
            }
        } else {
            for view in ageRequirementViews {
                view.isHidden = true
            }
        }
    }

    // MARK: - Session View Model Delegate

    func bookmarkImageChanged(_ bookmarkImage: UIImage, accessibilityLabel: String) {
        bookmarkButton.setImage(bookmarkImage, for: UIControlState())
        bookmarkButton.accessibilityLabel = accessibilityLabel
    }
}
