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
    @IBOutlet fileprivate var imageView: FaceDisplayingImageView!
    fileprivate lazy var noImageView: UIView = {
        let imageView = self.imageView
        
        let view = UIView()
        view.accessibilityLabel = "Placeholder Image"
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        view.topAnchor.constraint(equalTo: (imageView?.topAnchor)!).isActive = true
        view.leftAnchor.constraint(equalTo: (imageView?.leftAnchor)!).isActive = true
        view.bottomAnchor.constraint(equalTo: (imageView?.bottomAnchor)!).isActive = true
        view.rightAnchor.constraint(equalTo: (imageView?.rightAnchor)!).isActive = true
        view.backgroundColor = UIColor.gray
        
        let noImageImageView = UIImageView()
        
        let image = UIImage(named: "compact_camera")
        let template = image?.withRenderingMode(.alwaysTemplate)
        noImageImageView.image = template
        noImageImageView.tintColor = UIColor.white
        noImageImageView.contentMode = .center
        
        noImageImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noImageImageView)
        noImageImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        noImageImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        noImageImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        noImageImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        return view
    }()
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            if let _ = newValue {
                noImageView.isHidden = true
            } else {
                noImageView.isHidden = false
            }
        }
    }
    
    /// Location of a face in the image displayed in `imageView`.
    var faceRect: CGRect? {
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
