//
//  GuestCollectionViewCell.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestCollectionViewCell: UICollectionViewCell {
    // `dynamic` allows the use of UIAppearance to set a value.
    dynamic var highlightColor: UIColor = UIColor(white: 0.8, alpha: 1)

    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    private var photoShadowView: UIView!

    var viewModel: GuestViewModel? {
        didSet {
            guard let viewModel = self.viewModel else {
                return
            }

            nameLabel.text = viewModel.name
            
            let photo = viewModel.photo(true)
            photoImageView.image = photo
        }
    }

    override var highlighted: Bool {
        didSet {
            let backgroundColor: UIColor

            if self.highlighted {
                backgroundColor = highlightColor
            } else {
                backgroundColor = UIColor.clearColor()
            }

            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.contentView.backgroundColor = backgroundColor
            })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        photoShadowView = UIView()
        photoShadowView.frame = photoImageView.frame
        contentView.insertSubview(photoShadowView, belowSubview: photoImageView)
        
        let shadowLayer = photoShadowView.layer
        shadowLayer.shadowOffset = CGSize(width: 0, height: 0)
        shadowLayer.shadowRadius = 2
        shadowLayer.shadowOpacity = 0.25
        shadowLayer.shadowColor = UIColor(white: 0.0, alpha: 1).CGColor // black
        shadowLayer.shadowPath = UIBezierPath(ovalInRect: photoImageView.bounds).CGPath
        shadowLayer.shouldRasterize = true
        
        let imageLayer = self.photoImageView.layer
        imageLayer.cornerRadius = self.photoImageView.frame.width / 2
        imageLayer.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        let shadowLayer = photoShadowView.layer
        shadowLayer.rasterizationScale = window?.screen.scale ?? 1
    }
}
