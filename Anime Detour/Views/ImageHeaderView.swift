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
    @IBOutlet var imageView: UIImageView!
    
    /// Location of a face in the image displayed in `imageView`.
    var faceYRect: CGRect?
    
    /// The minimum distance to maintain between the face, if present,
    /// and the top and bottom edges of the `imageView`.
    private static var minFaceEdgePadding: CGFloat = 5
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let faceYRect = faceYRect, _ = imageView.image else {
            return
        }
        
        // If the imageView already is showing the face, don't change anything
        guard case let bounds = imageView.bounds where !bounds.contains(faceYRect) else {
            return
        }
        
        let boundsOrigin = bounds.origin
        let boundsSize = bounds.size
        
        let newOrigin: CGPoint
        let (bo, nY, xY) = (boundsOrigin.y, faceYRect.minY, faceYRect.maxY)
        
        switch (bo, nY, xY) {
        case _ where bo > nY && bo < xY:
            newOrigin = boundsOrigin
        case _ where bo < nY:
            newOrigin = CGPoint(x: boundsOrigin.x, y: nY - self.dynamicType.minFaceEdgePadding)
        case _ where bo > xY:
            newOrigin = CGPoint(x: boundsOrigin.x, y: boundsSize.height - xY - self.dynamicType.minFaceEdgePadding)
        default:
            newOrigin = boundsOrigin
        }
        
        let newBounds = CGRect(origin: newOrigin, size: boundsSize)
        imageView.bounds = newBounds
    }
}
