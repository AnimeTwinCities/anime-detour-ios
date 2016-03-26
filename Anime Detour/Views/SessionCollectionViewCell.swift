//
//  SessionCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SessionCollectionViewCell: UICollectionViewCell, SessionViewModelDelegate {
    // `dynamic` allows the use of UIAppearance to set a value.
    dynamic var highlightColor: UIColor = UIColor(white: 0.8, alpha: 1)

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var bookmarkButton: UIButton?
    @IBOutlet var colorView: UIView?

    var viewModel: SessionViewModel? {
        didSet {
            switch oldValue {
            case let .Some(oldValue) where oldValue.delegate as? SessionTableViewCell == self:
                oldValue.delegate = nil
            default:
                break
            }

            guard let viewModel = viewModel else {
                return
            }
            
            viewModel.delegate = self
            self.nameLabel.text = viewModel.name
            self.locationLabel.text = viewModel.location
            self.timeLabel.text = viewModel.dateAndTime
            
            self.bookmarkButton?.setImage(viewModel.bookmarkImage, forState: .Normal)
            
            if let color = viewModel.categoryColor {
                colorView?.hidden = false
                colorView?.backgroundColor = color
            } else {
                colorView?.hidden = true
            }
        }
    }

    override var highlighted: Bool {
        didSet {
            let backgroundColor: UIColor

            if self.highlighted {
                backgroundColor = highlightColor
            } else {
                backgroundColor = UIColor.clearColor()
            }

            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.contentView.backgroundColor = backgroundColor
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
        self.contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true
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
        self.bookmarkButton?.setImage(bookmarkImage, forState: .Normal)
        self.bookmarkButton?.accessibilityLabel = accessibilityLabel
    }
}
