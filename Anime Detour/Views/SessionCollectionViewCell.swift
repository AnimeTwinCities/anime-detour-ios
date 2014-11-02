//
//  SessionCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

/**
Displays Session information. Shows more information if its height exceeds
a certain threshold.
*/
class SessionCollectionViewCell: UICollectionViewCell, SessionViewModelDelegate {
    /// The height above which we will enable "large" mode.
    private let largeHeightThreshold: CGFloat = 120

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var bookmarkButton: UIButton!

    @IBOutlet var descriptionConstraints: [NSLayoutConstraint]!

    var viewModel: SessionViewModel? {
        didSet {
            if let oldValue = oldValue {
                if let delegate = oldValue.delegate as? SessionCollectionViewCell {
                    if delegate == self {
                        oldValue.delegate = nil
                    }
                }
            }

            viewModel?.delegate = self
            self.nameLabel.text = viewModel?.name
            self.descriptionLabel.text = viewModel?.sessionDescription
            self.locationLabel.text = viewModel?.location
            self.timeLabel.text = viewModel?.dateAndTime

            self.bookmarkButton.setImage(viewModel?.bookmarkImage, forState: .Normal)
        }
    }

    /// If `true`, the cell will display additional information, including the session description.
    private var isDetail: Bool! {
        didSet {
            if let oldValue = oldValue {
                // If the value is unchanged, do nothing.
                if oldValue == self.isDetail {
                    return
                }
            }

            if self.isDetail! {
                self.descriptionLabel.hidden = false
                self.addConstraints(self.descriptionConstraints)

                self.bookmarkButton.hidden = false
            } else {
                self.descriptionLabel.hidden = true
                self.removeConstraints(self.descriptionConstraints)

                self.bookmarkButton.hidden = true
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        // Set `isDetail` here its didSet will run.
        self.isDetail = false
    }

    override func layoutSubviews() {
        if self.frame.height > self.largeHeightThreshold {
            self.isDetail = true
        } else {
            self.isDetail = false
        }
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        if let viewModel = self.viewModel {
            viewModel.delegate = nil
        }
    }

    // MARK: Bookmarking

    @IBAction func toggleBookmark(sender: AnyObject) {
        self.viewModel?.toggleBookmarked()
    }

    // MARK: Session View Model Delegate

    func bookmarkImageChanged(bookmarkImage: UIImage) {
        self.bookmarkButton.setImage(bookmarkImage, forState: .Normal)
    }
}