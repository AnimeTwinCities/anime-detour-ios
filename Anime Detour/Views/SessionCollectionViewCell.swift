//
//  SessionCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

@objc protocol SessionCollectionViewCellDelegate {
    func sessionCellBookmarkButtonTapped(_ cell: SessionCollectionViewCell)
}

class SessionCollectionViewCell: UICollectionViewCell, AgeRequirementDisplayingView, SessionViewModelDelegate {
    // `dynamic` allows the use of UIAppearance to set a value.
    dynamic var highlightColor: UIColor = UIColor(white: 0.8, alpha: 1)
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var ageRequirementLabel: InsettableLabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var bookmarkButton: UIButton?
    @IBOutlet var colorView: UIView?
    
    @IBOutlet weak var sessionCellDelegate: SessionCollectionViewCellDelegate?

    var viewModel: SessionViewModel? {
        didSet {
            switch oldValue {
            case let .some(oldValue) where oldValue.delegate as? SessionTableViewCell == self:
                oldValue.delegate = nil
            default:
                break
            }

            guard let viewModel = viewModel else {
                return
            }
            
            viewModel.delegate = self
            self.nameLabel.text = viewModel.name
            
            showAgeRequirementOrHideLabel(forViewModel: viewModel)
            
            self.locationLabel.text = viewModel.location
            self.timeLabel.text = viewModel.dateAndTime
            
            self.bookmarkButton?.setImage(viewModel.bookmarkImage, for: UIControlState())
            
            if let color = viewModel.categoryColor {
                colorView?.isHidden = false
                colorView?.backgroundColor = color
            } else {
                colorView?.isHidden = true
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            let backgroundColor: UIColor

            if self.isHighlighted {
                backgroundColor = highlightColor
            } else {
                backgroundColor = UIColor.clear
            }

            UIView.animate(withDuration: 0.1, animations: { [contentView] () -> Void in
                contentView.backgroundColor = backgroundColor
            })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Without setting an `autoresizingMask`, the content view has a
        // mysterious 50pt width constraint that we don't want.
        // So just set it to autoresize.
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.translatesAutoresizingMaskIntoConstraints = true
    }

    override func prepareForReuse() {
        viewModel?.delegate = nil
    }

    // MARK: Bookmarking

    @IBAction func toggleBookmark(_ sender: AnyObject) {
        sessionCellDelegate?.sessionCellBookmarkButtonTapped(self)
    }

    // MARK: Session View Model Delegate

    func bookmarkImageChanged(_ bookmarkImage: UIImage, accessibilityLabel: String) {
        bookmarkButton?.setImage(bookmarkImage, for: UIControlState())
        bookmarkButton?.accessibilityLabel = accessibilityLabel
    }
}
