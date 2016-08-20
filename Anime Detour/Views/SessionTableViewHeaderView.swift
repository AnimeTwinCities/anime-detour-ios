//
//  SessionCollectionViewHeaderView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/25/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class SessionTableViewHeaderView: UITableViewHeaderFooterView {
    @IBOutlet fileprivate var nameLabel: UILabel!

    var title: String? {
        didSet {
            self.nameLabel.text = self.title
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    init(frame: CGRect) {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel = nameLabel

        super.init(reuseIdentifier: nil)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(nameLabel)

        let bindings = ["nameLabel" : nameLabel]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|-[nameLabel]-|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[nameLabel]-|", options: [], metrics: nil, views: bindings)

        let allConstraints = hConstraints + vConstraints
        self.addConstraints(allConstraints)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
