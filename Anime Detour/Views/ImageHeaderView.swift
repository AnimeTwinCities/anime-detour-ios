//
//  ImageHeaderView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/2/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

/**
 Displays an image. Attempts to keep a face, if present in the `imageView`'s image,
 visible.
 */
class ImageHeaderView: UIView {
    @IBOutlet var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var imageView: FaceDisplayingImageView!
    
    /// Location of a face in the image displayed in `imageView`.
    var faceBounds: CGRect? {
        get {
            return imageView.faceRect
        }
        set {
            imageView.faceRect = newValue
        }
    }
    
    /// The minimum distance to maintain between the face, if present,
    /// and the top and bottom edges of the `imageView`.
    private static var minFaceEdgePadding: CGFloat = 5
}
