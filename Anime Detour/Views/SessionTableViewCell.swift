//
//  SessionTableViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/17/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SessionTableViewCell: UITableViewCell, SessionViewModelDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var bookmarkButton: UIButton!

    /// Views which should only display in expanded "detail" mode
    @IBOutlet var detailViews: [UIView]!

    /// Layout constraints for use only in expanded "detail" mode
    @IBOutlet var detailConstraints: [NSLayoutConstraint]!

    /// Layout constraints for use only in compact "summary" mode
    @IBOutlet var summaryConstraints: [NSLayoutConstraint]!

    var viewModel: SessionViewModel? {
        didSet {
            switch oldValue {
            case let .Some(oldValue) where oldValue.delegate as? SessionTableViewCell == self:
                oldValue.delegate = nil
            default:
                break
            }

            if let viewModel = viewModel {
                viewModel.delegate = self
                self.nameLabel.text = viewModel.name
                self.locationLabel.text = viewModel.location
                self.timeLabel.text = viewModel.dateAndTime

                self.bookmarkButton.setImage(viewModel.bookmarkImage, forState: .Normal)
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        self.viewModel?.delegate = nil
    }

    // MARK: Bookmarking

    @IBAction func toggleBookmark(sender: AnyObject) {
        self.viewModel?.toggleBookmarked()
    }
    
    // MARK: Session View Model Delegate
    
    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String) {
        self.bookmarkButton.setImage(bookmarkImage, forState: .Normal)
        self.bookmarkButton.accessibilityLabel = accessibilityLabel
    }

}
