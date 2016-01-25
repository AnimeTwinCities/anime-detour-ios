//
//  FaceDisplayingImageView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/6/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

/**
 Always behaves as if the content mode were `UIViewContentMode.ScaleAspectFill`.
 */
class FaceDisplayingImageView: UIView {
    /**
     An image to display.
     */
    @IBInspectable var image: UIImage? {
        didSet {
            if image != oldValue {
                setNeedsDisplay()
            }
        }
    }

    /**
     The coordinates of the face in the image, in the image's coordinate system.
     */
    var faceRect: CGRect? {
        didSet {
            if faceRect != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        let drawingRect: CGRect
        
        guard let image = image else { return }
        
        defer {
            image.drawInRect(drawingRect)
        }
        
        let noChangesImageBounds = rectForAspectFillFor(image)
        
        guard let faceRect = faceRect where !noChangesImageBounds.contains(faceRect) else {
            // If we don't have a face rect, or the face falls in the part of the image we want to draw anyway,
            // just draw the image using aspect fill.
            drawingRect = noChangesImageBounds
            return
        }
        
        let imageSize = image.size
        let imageScalingFactor: CGFloat
        if case let widthFactor = imageSize.width / noChangesImageBounds.width where abs(widthFactor - 1) > 0.01 {
            imageScalingFactor = 1 / widthFactor
        } else {
            let heightFactor = imageSize.height / noChangesImageBounds.height
            imageScalingFactor = 1 / heightFactor
        }
        
        let scaledFaceRect = CGRect(x: faceRect.minX * imageScalingFactor, y: faceRect.minY  * imageScalingFactor, width: faceRect.width * imageScalingFactor, height: faceRect.height * imageScalingFactor)
        let scaledAndOffsetFaceRect = scaledFaceRect.offsetBy(dx: noChangesImageBounds.minX, dy: noChangesImageBounds.minY)
        
        let boundsAndNoChangesImageBoundsIntersect = bounds.intersect(noChangesImageBounds)
        if case let yOffset = scaledAndOffsetFaceRect.minY - boundsAndNoChangesImageBoundsIntersect.minY where yOffset < 0 {
            drawingRect = noChangesImageBounds.offsetBy(dx: 0, dy: -yOffset)
        } else if case let yOffset = scaledAndOffsetFaceRect.maxY - boundsAndNoChangesImageBoundsIntersect.maxY where yOffset > 0 {
            drawingRect = noChangesImageBounds.offsetBy(dx: 0, dy: -yOffset)
        } else {
            drawingRect = noChangesImageBounds
        }
    }
    
    private func rectForAspectFillFor(image: UIImage) -> CGRect {
        let imageSize = image.size
        
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        let imageAspect = imageWidth / imageHeight
        let boundsAspect = bounds.width / bounds.height
        let (drawnWidth, drawnHeight, leftX, topY): (CGFloat, CGFloat, CGFloat, CGFloat)
        if imageAspect > boundsAspect {
            // The image is wider than our bounds
            drawnHeight = bounds.height
            drawnWidth = drawnHeight * imageAspect
            leftX = -(drawnWidth - bounds.width) / 2
            topY = 0
        } else {
            drawnWidth = bounds.width
            drawnHeight = drawnWidth / imageAspect
            leftX = 0
            topY = -(drawnHeight - bounds.height) / 2
        }
        
        return CGRect(origin: CGPoint(x: leftX, y: topY), size: CGSize(width: drawnWidth, height: drawnHeight))
    }
}
