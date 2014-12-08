//
//  SessionCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
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
    @IBOutlet var typesLabel: UILabel!
    @IBOutlet var primaryTypeIndicator: UIView!
    @IBOutlet var backgroundPrimaryTypeIndicator: UIView!

    /// Views which should only display in expanded "detail" mode
    @IBOutlet var detailViews: [UIView]!

    /// Layout constraints for use only in expanded "detail" mode
    @IBOutlet var detailConstraints: [NSLayoutConstraint]!

    /// Layout constraints for use only in compact "summary" mode
    @IBOutlet var summaryConstraints: [NSLayoutConstraint]!

    var viewModel: SessionViewModel? {
        didSet {
            switch oldValue {
            case let .Some(oldValue) where oldValue.delegate as? SessionCollectionViewCell == self:
                oldValue.delegate = nil
            default:
                break
            }

            if let viewModel = viewModel {
                viewModel.delegate = self
                self.nameLabel.text = viewModel.name
                self.descriptionLabel.text = viewModel.sessionDescription
                self.locationLabel.text = viewModel.location
                self.timeLabel.text = viewModel.dateAndTime
                self.typesLabel.text = viewModel.type
                self.primaryTypeIndicator.backgroundColor = viewModel.primaryColor
                self.backgroundPrimaryTypeIndicator.backgroundColor = viewModel.primaryColor

                self.bookmarkButton.setImage(viewModel.bookmarkImage, forState: .Normal)
            }
        }
    }

    /// If `true`, the cell will display additional information, including the session description.
    private var isDetail: Bool! {
        didSet {
            let isDetail = self.isDetail!

            // If the value is unchanged, do nothing.
            switch oldValue {
            case .Some(oldValue) where oldValue == isDetail:
                return
            default:
                break
            }

            var viewsToRemove: [UIView]
            var viewsToAdd: [UIView]
            var toRemove: [NSLayoutConstraint]
            var toAdd: [NSLayoutConstraint]
            if isDetail {
                for view in self.detailViews {
                    self.contentView.addSubview(view)
                }

                toAdd = self.detailConstraints
                toRemove = self.summaryConstraints

                self.backgroundPrimaryTypeIndicator.hidden = true
            } else {
                for view in self.detailViews {
                    view.removeFromSuperview()
                }

                toAdd = self.summaryConstraints
                toRemove = self.detailConstraints

                self.backgroundPrimaryTypeIndicator.hidden = false
            }

            self.removeConstraints(toRemove)
            self.addConstraints(toAdd)
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        // Set `isDetail` here its didSet will run.
        self.isDetail = false

        let leftMargin = self.layoutMargins.left

        // Set rounded corners on the background session type indicator's layer.
        let backgroundPrimaryTypeLayer = self.backgroundPrimaryTypeIndicator.layer
        backgroundPrimaryTypeLayer.cornerRadius = leftMargin
        backgroundPrimaryTypeLayer.masksToBounds = true

        // Set rounded corners on the session type indicator's layer.
        let primaryTypeLayer = self.primaryTypeIndicator.layer
        primaryTypeLayer.cornerRadius = 10.0 // half the width of the type indicator view
        primaryTypeLayer.masksToBounds = true
    }

    override func layoutSubviews() {
        let overHeightThreshold = self.frame.height > self.largeHeightThreshold
        self.isDetail = overHeightThreshold

        super.layoutSubviews()
    }

    override func prepareForReuse() {
        self.viewModel?.delegate = nil
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