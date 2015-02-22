//
//  UICollectionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/22/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

extension UICollectionViewFlowLayout {
    // Get the y-coordinate for the first item,
    // including section headers, in a section.
    func yCoordinateForFirstItemInSection(section: Int) -> CGFloat {
        let indexPath = NSIndexPath(forItem: 0, inSection: section)

        if let headerAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: indexPath) {
            return headerAttributes.frame.minY
        }
        if let itemAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) {
            return itemAttributes.frame.minY
        }

        // not found
        fatalError("No header or item found for section \(section)")
    }
}

extension StickyHeaderFlowLayout {
    override func yCoordinateForFirstItemInSection(section: Int) -> CGFloat {
        let indexPath = NSIndexPath(forItem: 0, inSection: section)

        if let headerAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: indexPath) {
            var minY = headerAttributes.frame.minY
            if self.headerEnabled {
                minY -= self.headerHeight
            }

            return minY
        }
        if let itemAttributes = self.layoutAttributesForItemAtIndexPath(indexPath) {
            var minY = itemAttributes.frame.minY
            if self.headerEnabled {
                minY -= self.headerHeight
            }

            return minY
        }

        // not found
        fatalError("No header or item found for section \(section)")
    }
}