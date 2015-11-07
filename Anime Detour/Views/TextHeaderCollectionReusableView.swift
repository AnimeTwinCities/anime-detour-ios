//
//  TextHeaderCollectionReusableView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

/**
Simple header view with a full-width label.
The label's text color is set to the view's tint color every time
the tint color changes, so avoid setting the text color directly.
*/
class TextHeaderCollectionReusableView: UICollectionReusableView {
    @IBOutlet var titleLabel: UILabel!

    convenience init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel = titleLabel

        super.init(frame: frame)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)

        let bindings = ["titleLabel" : titleLabel]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-[titleLabel]-|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[titleLabel]-|", options: [], metrics: nil, views: bindings)

        let allConstraints = hConstraints + vConstraints
        self.addConstraints(allConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
