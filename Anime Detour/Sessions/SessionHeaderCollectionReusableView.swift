//
//  SessionHeaderCollectionReusableView.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

class SessionHeaderCollectionReusableView: UICollectionReusableView {
    @IBOutlet var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        backgroundColor = .dev_sessionHeaderBackgroundColor
        timeLabel.font = .dev_sessionTimeHeaderFont
    }
}

extension SessionHeaderCollectionReusableView: ReusableItem {
    static let reuseID: String = String(describing: SessionHeaderCollectionReusableView.self)
}
