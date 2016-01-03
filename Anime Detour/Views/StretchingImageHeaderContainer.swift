//
//  StretchingImageHeaderContainer.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/3/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import Foundation

protocol StretchingImageHeaderContainer {
    var imageHeaderView: ImageHeaderView! { get }
    
    /// The aspect ratio (width / height) of the photo image view.
    var photoAspect: CGFloat { get }
    
    var view: UIView! { get }
    
    /// Adjust the frame of the header view to maintain our target aspect ratio.
    func updateHeaderSize()
    
    /// Adjust the top constraint of the image header view's image,
    /// so more of the image is visible if the user over-scrolls the scroll view.
    func updateHeaderImageTopConstraint(scrollView: UIScrollView)
}

extension StretchingImageHeaderContainer {
    func updateHeaderImageTopConstraint(scrollView: UIScrollView) {
        let verticalOffset = scrollView.contentOffset.y
        let verticalInset = scrollView.contentInset.top
        
        let total = verticalOffset + verticalInset
        
        // If `verticalOffset` is < 0, i.e. the scroll view was overscrolled down such that the
        // top of its content is lower on the screen than it would be if the user were not touching
        // the screen, then extend the top of the image header view's image view to fill the empty space.
        if total < 0 {
            self.imageHeaderView.imageViewTopConstraint.constant = total
        } else {
            self.imageHeaderView.imageViewTopConstraint.constant = 0
        }
    }
    
    func updateHeaderSize() {
        let headerFrame = self.imageHeaderView.frame
        let newHeight = round(self.view.frame.width / self.photoAspect)
        let newFrame = CGRect(origin: headerFrame.origin, size: CGSize(width: headerFrame.width, height: newHeight))
        self.imageHeaderView.frame = newFrame
    }
}
