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
    func yCoordinateForFirstItemInSection(_ section: Int) -> CGFloat {
        let indexPath = IndexPath(item: 0, section: section)

        if let headerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
            return headerAttributes.frame.minY
        }
        if let itemAttributes = layoutAttributesForItem(at: indexPath) {
            return itemAttributes.frame.minY
        }

        // not found
        fatalError("No header or item found for section \(section)")
    }
}

extension StickyHeaderFlowLayout {
    override func yCoordinateForFirstItemInSection(_ section: Int) -> CGFloat {
        let indexPath = IndexPath(item: 0, section: section)

        if let headerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
            var minY = headerAttributes.frame.minY
            if headerEnabled {
                minY -= self.headerHeight
            }

            return minY
        }
        if let itemAttributes = layoutAttributesForItem(at: indexPath) {
            var minY = itemAttributes.frame.minY
            if headerEnabled {
                minY -= self.headerHeight
            }

            return minY
        }

        // not found
        fatalError("No header or item found for section \(section)")
    }
}
