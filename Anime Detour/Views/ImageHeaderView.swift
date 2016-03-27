//
//  ImageHeaderView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/2/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

/**
 Displays an image. Attempts to keep a face, if present in the `imageView`'s image, visible.
 
 If no image is set, shows a placeholder.
 */
class ImageHeaderView: UIView {
    @IBOutlet var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var imageView: FaceDisplayingImageView!
    private lazy var noImageView: UIView = {
        let imageView = self.imageView
        
        let view = UIView()
        view.accessibilityLabel = "Placeholder Image"
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        view.topAnchor.constraintEqualToAnchor(imageView.topAnchor).active = true
        view.leftAnchor.constraintEqualToAnchor(imageView.leftAnchor).active = true
        view.bottomAnchor.constraintEqualToAnchor(imageView.bottomAnchor).active = true
        view.rightAnchor.constraintEqualToAnchor(imageView.rightAnchor).active = true
        view.backgroundColor = UIColor.adr_mediumGray
        
        let noImageImageView = UIImageView()
        
        let image = UIImage(named: "compact_camera")
        let template = image?.imageWithRenderingMode(.AlwaysTemplate)
        noImageImageView.image = template
        noImageImageView.tintColor = UIColor.whiteColor()
        noImageImageView.contentMode = .Center
        
        noImageImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noImageImageView)
        noImageImageView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        noImageImageView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        noImageImageView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        noImageImageView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        
        return view
    }()
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            if let _ = newValue {
                noImageView.hidden = true
            } else {
                noImageView.hidden = false
            }
        }
    }
    
    /// Location of a face in the image displayed in `imageView`.
    var faceBounds: CGRect? {
        get {
            return imageView.faceRect
        }
        set {
            imageView.faceRect = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Instantiate `noImageView` if it has not already.
        _ = noImageView
    }
}
