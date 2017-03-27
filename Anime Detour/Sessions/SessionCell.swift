//
//  SessionCell.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 Display data from a `SessionViewModel`. Star toggle events are passed up the responder chain
 using `UIResponder.adr_toggleStarred(forSessionID:)`.
 */
class SessionCell: UICollectionViewCell, AgeRequirementDisplayingView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    @IBOutlet var ageRequirementLabel: InsettableLabel?
    @IBOutlet var trackLabel: UILabel!
    
    @IBOutlet var colorView: UIView!
    @IBOutlet var starButton: UIButton!
    
    // `dynamic` allows the use of UIAppearance to set a value.
    dynamic var highlightColor: UIColor = UIColor(white: 0.8, alpha: 1)
    
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
    
    var viewModel: SessionViewModel? {
        didSet {
            titleLabel.text = viewModel?.title
            subtitleLabel.text = viewModel?.room
            
            if let track = viewModel?.category?.name {
                trackLabel.text = track
                trackLabel.isHidden = false
            } else {
                trackLabel.isHidden = true
            }
            
            trackLabel.textColor = viewModel?.color ?? .black
            colorView.backgroundColor = viewModel?.color
            
            let image: UIImage
            if viewModel?.isStarred ?? false {
                image = #imageLiteral(resourceName: "star_filled")
            } else {
                image = #imageLiteral(resourceName: "star")
            }
            starButton.setImage(image, for: .normal)
            
            showAgeRequirementOrHideLabel(forViewModel: viewModel)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    @IBAction func toggleStarred(sender: AnyObject?) {
        guard let identifier = viewModel?.sessionID else {
            NSLog("Tried to toggle session starred state without a view model.")
            return
        }
        
        adr_toggleStarred(forSessionID: identifier)
    }
}

extension SessionCell: ReusableItem {
    static let reuseID: String = String(describing: SessionCell.self)
}

extension UIResponder {
    func adr_toggleStarred(forSessionID identifier: String) {
        next?.adr_toggleStarred(forSessionID: identifier)
    }
}
