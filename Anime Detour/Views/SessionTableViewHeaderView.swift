//
//  SessionCollectionViewHeaderView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/25/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class SessionTableViewHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private var nameLabel: UILabel!

    var title: String? {
        didSet {
            self.nameLabel.text = self.title
        }
    }

    convenience init() {
        self.init(frame: CGRectZero)
    }

    init(frame: CGRect) {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel = nameLabel

        super.init(reuseIdentifier: nil)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(nameLabel)

        let bindings = ["nameLabel" : nameLabel]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-[nameLabel]-|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[nameLabel]-|", options: [], metrics: nil, views: bindings)

        let allConstraints = hConstraints + vConstraints
        self.addConstraints(allConstraints)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
