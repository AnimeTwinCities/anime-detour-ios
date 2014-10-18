//
//  SessionCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

class SessionCollectionViewCell: UICollectionViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var locationLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var viewModel: SessionViewModel? {
        didSet {
            self.nameLabel.text = viewModel?.name
            self.descriptionLabel.text = viewModel?.sessionDescription
            self.timeLabel.text = viewModel?.dateAndTime
        }
    }
}