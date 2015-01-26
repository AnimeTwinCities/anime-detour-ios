//
//  GuestView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestView: UIView {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var bioView: UITextView!
    @IBOutlet var imageZeroHeightConstraint: NSLayoutConstraint!

    var viewModel: GuestViewModel! {
        didSet {
            self.imageView.image = self.viewModel.photo
            self.imageZeroHeightConstraint.priority = self.viewModel.photo == nil ? 1000 : 1
            self.nameLabel.text = self.viewModel.name
            self.bioView.attributedText = self.viewModel.htmlBio
        }
    }
}
