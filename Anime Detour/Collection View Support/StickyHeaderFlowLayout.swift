//
//  StickyHeaderFlowLayout.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

/**
Provides for a header that "sticks" to the top of the layout, in front of
all other views.
*/
class StickyHeaderFlowLayout: UICollectionViewFlowLayout {
    class var StickyHeaderElementKind: String {
        return "StickyHeaderElementKind"
    }

    @IBInspectable var headerEnabled: Bool = true
    @IBInspectable var headerHeight: CGFloat = 50

    // Top inset for the sticky header, e.g. to move it under the navigation controller
    @IBInspectable var headerTopOffset: CGFloat = 0 {
        didSet {
            if self.headerTopOffset == oldValue {
                return
            }

            let invalidationContext = self.invalidationContextForBoundsChange(self.collectionView?.bounds ?? CGRect.zeroRect)
            self.setStickyHeaderInvalid(invalidationContext)
            self.invalidateLayoutWithContext(invalidationContext)
        }
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let superAttributes = super.layoutAttributesForElementsInRect(rect) ?? []
        var attributes = superAttributes.map(self.copy)

        // No sticky header if there are no sections
        if self.headerEnabled && (self.collectionView?.numberOfSections() ?? 0) != 0 {
            // Offset all non-sticky-header views by the sticky header's height
            for itemAttributes in attributes {
                self.offsetForStickyHeader(itemAttributes)
            }
            
            let indexPath = NSIndexPath(forItem: 0, inSection: 0)
            if let headerAttributes = self.layoutAttributesForSupplementaryViewOfKind(StickyHeaderFlowLayout.StickyHeaderElementKind, atIndexPath: indexPath).map(self.copy) {
                attributes.append(headerAttributes)
            }
        }

        return attributes
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItemAtIndexPath(indexPath).map(self.copy) else {
            return nil
        }

        // Offset all non-sticky-header views by the sticky header's height
        self.offsetForStickyHeader(attributes)

        return attributes
    }

    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes: UICollectionViewLayoutAttributes?

        switch elementKind {
        case StickyHeaderFlowLayout.StickyHeaderElementKind:
            let cvOffset = self.collectionView?.contentOffset ?? CGPoint.zeroPoint
            let cvFrame = self.collectionView?.frame ?? CGRect.zeroRect
            var stickySize = cvFrame.size
            stickySize.height = self.headerHeight

            let stickyOrigin = CGPoint(x: 0, y: self.headerTopOffset + cvOffset.y)
            let stickyFrame = CGRect(origin: stickyOrigin, size: stickySize)

            let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
            headerAttributes.frame = stickyFrame
            // The default `zIndex` for `UICollectionElementKindSectionHeader` attributes on iOS 9
            // is `10`. Set the sticky header's `zIndex` much higher.
            headerAttributes.zIndex = 100
            attributes = headerAttributes
        default:
            attributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath).map(self.copy)
            
            // Offset all non-sticky-header views by the sticky header's height
            if let attributes = attributes {
                self.offsetForStickyHeader(attributes)
            }
        }

        return attributes
    }

    override func collectionViewContentSize() -> CGSize {
        var size = super.collectionViewContentSize()

        // All non-sticky-header views are offset by the sticky header's height,
        // so add that height to super's size
        if self.headerEnabled {
            size.height += self.headerHeight
        }

        return size
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if !self.headerEnabled {
            return super.shouldInvalidateLayoutForBoundsChange(newBounds)
        }

        return true
    }

    private func offsetForStickyHeader(attributes: UICollectionViewLayoutAttributes) {
        if self.headerEnabled {
            let frame = attributes.frame
            let offsetFrame = frame.rectByOffsetting(dx: 0, dy: self.headerHeight)
            attributes.frame = offsetFrame
        }
    }

    private func setStickyHeaderInvalid(invalidationContext: UICollectionViewLayoutInvalidationContext) {
        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
        invalidationContext.invalidateSupplementaryElementsOfKind(StickyHeaderFlowLayout.StickyHeaderElementKind, atIndexPaths: [indexPath])
    }
    
    /**
    Create a copy of layout attributes. Useful when the attributes' frame will
    be modified, since UICollectionViewFlowLayout caches attributes but
    can't because we're possibly modifying their frames to offset for our header.
    */
    private func copy(attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return attributes.copy() as! UICollectionViewLayoutAttributes
    }
}
