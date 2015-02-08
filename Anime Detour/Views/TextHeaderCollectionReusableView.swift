//
//  TextHeaderCollectionReusableView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class TextHeaderCollectionReusableView: UICollectionReusableView {
    @IBOutlet var titleLabel: UILabel!

    convenience override init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.titleLabel = titleLabel

        super.init(frame: frame)

        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(titleLabel)

        let bindings: NSDictionary = ["titleLabel" : titleLabel]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-[titleLabel]-|", options: .allZeros, metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[titleLabel]-|", options: .allZeros, metrics: nil, views: bindings)

        let allConstraints = hConstraints + vConstraints
        self.addConstraints(allConstraints)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
