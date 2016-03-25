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
    static let targetFaceCenterYRatio: CGFloat = 1 / 3
    
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
        guard let image = image else { return }
        
        let drawingRect: CGRect
        
        defer {
            image.drawInRect(drawingRect)
        }
        
        let noChangesImageBounds = rectForAspectFillFor(image)
        
        guard let faceRect = faceRect else {
            // If we don't have a face rect
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
        let scaledFaceSize = scaledFaceRect.size
        
        // The bounds of the face in the image, in the view's coordinate system.
        let scaledAndOffsetFaceRect = scaledFaceRect.offsetBy(dx: noChangesImageBounds.minX, dy: noChangesImageBounds.minY)
        
        let scaledAndOffsetFaceHeight = scaledAndOffsetFaceRect.height
        let isFaceCenterAboveImageCenter = scaledAndOffsetFaceRect.midY < (noChangesImageBounds.height / 2)
        let isFaceBiggerThanView = scaledAndOffsetFaceHeight > bounds.height
        
        let viewAndImageBoundsIntersect = bounds.intersect(noChangesImageBounds)
        
        let offsetForTargetFraction: CGFloat
        
        if isFaceBiggerThanView { // face is bigger than the view, so center it in the view
            let faceMiddleTargetRect = CGRect(origin: CGPoint(x: scaledAndOffsetFaceRect.minX, y: bounds.midY - scaledAndOffsetFaceHeight / 2), size: scaledFaceSize)
            let targetTopYOffset = faceMiddleTargetRect.minY - scaledAndOffsetFaceRect.minY
            
            offsetForTargetFraction = targetTopYOffset
        } else if isFaceCenterAboveImageCenter { // face center is above the center of the image, in the image's coordinates
            let faceTopTargetCenterY = bounds.minY + bounds.height * FaceDisplayingImageView.targetFaceCenterYRatio
            
            let doesFaceFitIfAtTopTarget =  faceTopTargetCenterY > (scaledAndOffsetFaceHeight / 2)
            let faceTopTargetRect: CGRect
            if doesFaceFitIfAtTopTarget {
                // Face would be fully in view at the top target, so position it there
                faceTopTargetRect = CGRect(origin: CGPoint(x: scaledAndOffsetFaceRect.minX, y: faceTopTargetCenterY - (scaledAndOffsetFaceHeight / 2)), size: scaledFaceSize)
            } else {
                // Face would not be fully in view at the top target, so just position it at the top of the view
                faceTopTargetRect = CGRect(origin: CGPoint(x: scaledAndOffsetFaceRect.minX, y: bounds.minY), size: scaledFaceSize)
            }
            
            let containsTopTarget = viewAndImageBoundsIntersect.contains(faceTopTargetRect)
            
            if containsTopTarget, case let targetTopYOffset = faceTopTargetRect.minY - scaledAndOffsetFaceRect.minY where targetTopYOffset > 0 {
                offsetForTargetFraction = targetTopYOffset
            } else {
                offsetForTargetFraction = 0
            }
        } else { // face center is below the center of the image, in the image's coordinates
            let faceBottomTargetCenterY = bounds.maxY - bounds.height * FaceDisplayingImageView.targetFaceCenterYRatio
            
            let doesFaceFitIfAtBottomTarget = (bounds.height - faceBottomTargetCenterY) > (scaledAndOffsetFaceHeight / 2)
            let faceBottomTargetRect: CGRect
            if doesFaceFitIfAtBottomTarget {
                // Face would be fully in view at the bottom target, so position it there
                faceBottomTargetRect = CGRect(origin: CGPoint(x: scaledAndOffsetFaceRect.minX, y: faceBottomTargetCenterY - (scaledAndOffsetFaceHeight / 2)), size: scaledFaceSize)
            } else {
                // Face would not be fully in view at the bottom target, so just position it at the bottom of the view
                faceBottomTargetRect = CGRect(origin: CGPoint(x: scaledAndOffsetFaceRect.minX, y: bounds.maxY - scaledAndOffsetFaceHeight), size: scaledFaceSize)
            }
            
            let containsBottomTarget = viewAndImageBoundsIntersect.contains(faceBottomTargetRect)
            
            if containsBottomTarget, case let targetBottomYOffset = faceBottomTargetRect.minY - scaledAndOffsetFaceRect.minY where targetBottomYOffset < 0 {
                offsetForTargetFraction = targetBottomYOffset
            } else {
                offsetForTargetFraction = 0
            }
        }
        
        let baseDrawingRect = noChangesImageBounds
        let drawingRectOffsetForTargetFraction = baseDrawingRect.offsetBy(dx: 0, dy: offsetForTargetFraction)
        
        let displayedPartOfNoChangesImageBounds = bounds.intersect(noChangesImageBounds)
        let displayedPartOfDrawingRectOffsetForTargetFraction = bounds.intersect(drawingRectOffsetForTargetFraction)
        let differenceInDisplayedHeight = displayedPartOfNoChangesImageBounds.height - displayedPartOfDrawingRectOffsetForTargetFraction.height
        if differenceInDisplayedHeight < 0.01 {
            drawingRect = drawingRectOffsetForTargetFraction
        } else {
            drawingRect = drawingRectOffsetForTargetFraction.offsetBy(dx: 0, dy: -differenceInDisplayedHeight)
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
