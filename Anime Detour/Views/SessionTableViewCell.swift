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
    @IBOutlet var bookmarkButton: UIButton?

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
            nameLabel.text = viewModel.name
            locationLabel.text = viewModel.location
            timeLabel.text = viewModel.dateAndTime
            
            bookmarkButton?.setImage(viewModel.bookmarkImage, forState: .Normal)
        }
    }

    required init?(coder aDecoder: NSCoder) {
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
        bookmarkButton?.setImage(bookmarkImage, forState: .Normal)
        bookmarkButton?.accessibilityLabel = accessibilityLabel
    }

}
