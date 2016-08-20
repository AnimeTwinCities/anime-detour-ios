//
//  SessionTableViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/17/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SessionTableViewCell: UITableViewCell, AgeRequirementDisplayingView, SessionViewModelDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var ageRequirementLabel: InsettableLabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var colorView: UIView?

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
            
            showAgeRequirementOrHideLabel(forViewModel: viewModel)
            
            viewModel.delegate = self
            nameLabel.text = viewModel.name
            locationLabel.text = viewModel.location
            timeLabel.text = viewModel.dateAndTime
            
            if let color = viewModel.categoryColor {
                colorView?.isHidden = false
                colorView?.backgroundColor = color
            } else {
                colorView?.isHidden = true
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: UITableViewCell
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let colorViewColor = colorView?.backgroundColor
        defer {
            colorView?.backgroundColor = colorViewColor
        }
        super.setHighlighted(highlighted, animated: animated)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let colorViewColor = colorView?.backgroundColor
        defer {
            colorView?.backgroundColor = colorViewColor
        }
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        self.viewModel?.delegate = nil
    }
    
    // MARK: Session View Model Delegate
    
    func bookmarkImageChanged(_ bookmarkImage: UIImage, accessibilityLabel: String) {
        // empty
    }
}
