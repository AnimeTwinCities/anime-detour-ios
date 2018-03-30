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
    static let StickyHeaderElementKind: String = "StickyHeaderElementKind"
    static let StickyHeaderIndexPath = IndexPath(item: 0, section: 0)

    @IBInspectable var headerEnabled: Bool = true
    @IBInspectable var headerHeight: CGFloat = 50

    // Top inset for the sticky header, e.g. to move it under the navigation controller
    @IBInspectable var headerTopOffset: CGFloat = 0 {
        didSet {
            if headerTopOffset == oldValue {
                return
            }

            let invalidationContext = self.invalidationContext(forBoundsChange: collectionView?.bounds ?? CGRect.zero)
            setStickyHeaderInvalid(invalidationContext)
            invalidateLayout(with: invalidationContext)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let superAttributes = super.layoutAttributesForElements(in: rect) ?? []
        var attributes = superAttributes.map(copy)

        // No sticky header if there are no sections
        if headerEnabled && (collectionView?.numberOfSections ?? 0) != 0 {
            // Offset all non-sticky-header views by the sticky header's height
            for itemAttributes in attributes {
                offsetForStickyHeader(itemAttributes)
            }
            
            let headerAttributes = layoutAttributesForStickyHeader(at: StickyHeaderFlowLayout.StickyHeaderIndexPath)
            attributes.append(headerAttributes)
        }

        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath).map(copy) else {
            return nil
        }

        // Offset all non-sticky-header views by the sticky header's height
        offsetForStickyHeader(attributes)

        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes: UICollectionViewLayoutAttributes?

        if elementKind == StickyHeaderFlowLayout.StickyHeaderElementKind {
            attributes = layoutAttributesForStickyHeader(at: indexPath)
        } else {
            attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath).map(copy)
            
            // Offset all non-sticky-header views by the sticky header's height
            if let attributes = attributes {
                offsetForStickyHeader(attributes)
            }
        }

        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize

        // All non-sticky-header views are offset by the sticky header's height,
        // so add that height to super's size
        if headerEnabled {
            size.height += headerHeight
        }

        return size
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if headerEnabled {
            let oldBounds = collectionView?.bounds ?? CGRect.zero
            if oldBounds.minY != newBounds.minY {
                return true
            }
        }
        
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        setStickyHeaderInvalid(context)
        return context
    }

    fileprivate func offsetForStickyHeader(_ attributes: UICollectionViewLayoutAttributes) {
        if headerEnabled {
            let frame = attributes.frame
            let offsetFrame = frame.offsetBy(dx: 0, dy: headerHeight)
            attributes.frame = offsetFrame
        }
    }

    fileprivate func setStickyHeaderInvalid(_ invalidationContext: UICollectionViewLayoutInvalidationContext) {
        invalidationContext.invalidateSupplementaryElements(ofKind: StickyHeaderFlowLayout.StickyHeaderElementKind, at: [StickyHeaderFlowLayout.StickyHeaderIndexPath])
    }
    
    /**
    Create a copy of layout attributes. Useful when the attributes' frame will
    be modified, since UICollectionViewFlowLayout caches attributes but
    can't because we're possibly modifying their frames to offset for our header.
    */
    private func copy(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return attributes.copy() as! UICollectionViewLayoutAttributes
    }

    private func layoutAttributesForStickyHeader(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let cvOffset = collectionView?.contentOffset ?? CGPoint.zero
        let cvBounds = collectionView?.bounds ?? CGRect.zero
        let stickySize = CGSize(width: cvBounds.width, height: headerHeight)

        // Make sure that the sticky header's minY isn't negative.
        // When over-scrolling past the top of the collection view, if we allow the sticky header's
        // minY to go negative, the sticky header does not stay in the correct position relative to other
        // elements in the collection view.
        // Clamping the minY to zero results in it staying in the correct relative position in that case.
        let stickyMinY = max(headerTopOffset + cvOffset.y, 0)
        let stickyOrigin = CGPoint(x: 0, y: stickyMinY)
        let stickyFrame = CGRect(origin: stickyOrigin, size: stickySize)

        let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: StickyHeaderFlowLayout.StickyHeaderElementKind, with: indexPath)
        headerAttributes.frame = stickyFrame
        // The default `zIndex` for `UICollectionElementKindSectionHeader` attributes on iOS 9
        // is `10`. Set the sticky header's `zIndex` much higher, so the sticky header is
        // higher than section headers.
        headerAttributes.zIndex = 100

        return headerAttributes
    }
}
