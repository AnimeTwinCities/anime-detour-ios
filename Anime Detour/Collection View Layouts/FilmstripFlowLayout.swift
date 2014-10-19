//
//  FilmstripFlowLayout.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

/**
Collection view layout that shows each section in a film strip, i.e. a horizontally scrolling list.
Otherwise similar to a standard flow layout.
*/
class FilmstripFlowLayout: UICollectionViewFlowLayout {
    /// Dictionary of section numbers to scroll offsets
    private var scrollingOffsets: [Int : Int] = [:]
    lazy private var positiveRect = CGRect(x: 0, y: 0, width: Int.max, height: Int.max)
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let positiveRect = rect.rectByIntersecting(self.positiveRect)
        let size = self.itemSize
        let lineSpacing = self.minimumLineSpacing
        let cellSpacing = self.minimumInteritemSpacing
        let headerSize = self.headerReferenceSize
        
        let sectionHeight = headerSize.height + lineSpacing + size.height + lineSpacing
        let sectionsBeforeRect = Int(floor(positiveRect.minY / sectionHeight))
        let lastPossibleSectionInRect = Int(floor(positiveRect.maxY / sectionHeight))
        
        let totalSections = self.collectionView?.numberOfSections() ?? 0
        if totalSections == 0 {
            return [AnyObject]()
        }
        
        let firstSectionInRect = Int(min(sectionsBeforeRect, totalSections - 1))
        let lastSectionInRect = Int(min(totalSections, lastPossibleSectionInRect))
        let sectionsInRect = firstSectionInRect..<lastSectionInRect
        
        let maxItemsPerSectionInRect = Int(ceil(positiveRect.width / (size.width + cellSpacing)))
        
        let itemsPerSectionInRect: [Int : [Int]] = { () -> [Int : [Int]] in
            var itemSectionsAndNumbers = [Int : [Int]]()
            
            for section in sectionsInRect {
                let scrollOffsetForSection = self.scrollingOffsets[section] ?? 0
                let xOffsetForFirstItem: CGFloat = floor(positiveRect.minX / ceil(size.width + cellSpacing))
                
                let itemsInSection = self.collectionView?.numberOfItemsInSection(section) ?? 0
                
                let firstPossibleItemInRect = Int(ceil(positiveRect.minX / max(xOffsetForFirstItem, CGFloat(1))))
                let firstItemInRect = Int(min(itemsInSection, firstPossibleItemInRect))
                
                var itemNumbers = [Int]()
                for itemNumber in firstItemInRect..<itemsInSection {
                    let xOffsetForItemNumber: CGFloat = ceil((size.width + cellSpacing) * CGFloat(itemNumber)) + xOffsetForFirstItem
                    if xOffsetForItemNumber <= positiveRect.maxX {
                        itemNumbers.append(itemNumber)
                    } else {
                        break
                    }
                }

                itemSectionsAndNumbers[section] = itemNumbers
            }
            
            return itemSectionsAndNumbers
        }()
        
        var attributes: [UICollectionViewLayoutAttributes] = []
        for (section, itemNumbers) in itemsPerSectionInRect {
            for itemNumber in itemNumbers {
                attributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: itemNumber, inSection: section)))
            }
        }
        
        return attributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let size = self.itemSize
        let lineSpacing = self.minimumLineSpacing
        let cellSpacing = self.minimumInteritemSpacing
        let headerSize = self.headerReferenceSize
        
        let xOffsetForItemNumber: CGFloat = ceil((size.width + cellSpacing) * CGFloat(indexPath.item))
        let yOffsetForSectionNumber: CGFloat = ceil((size.height + lineSpacing + headerSize.height) * CGFloat(indexPath.section))
        
        let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        attributes.frame = CGRect(origin: CGPoint(x: xOffsetForItemNumber + CGFloat(self.scrollingOffsets[indexPath.section] ?? 0), y: yOffsetForSectionNumber), size: size)
        
        return attributes
    }
    
    override func collectionViewContentSize() -> CGSize {
        // Find the size needed of the rect that starts at 0,0 and ends at the bottom right
        // coordinates of the last collection view item. If the size is wider than the collection view's
        // frame, trim it down, then return it.
        
        let numberOfSections = self.collectionView?.numberOfSections() ?? 0
        if numberOfSections == 0 {
            return CGSizeZero
        }
        
        let itemsInLastSection = self.collectionView?.numberOfItemsInSection(numberOfSections - 1) ?? 0
        if itemsInLastSection == 0 {
            return CGSizeZero
        }
        
        let attributesForLastSection = self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: itemsInLastSection - 1, inSection: numberOfSections - 1))
        let startsAtZero = CGRectUnion(attributesForLastSection.frame, CGRectZero)
        
        var collectionViewFrame = self.collectionView?.frame ?? CGRectZero
        collectionViewFrame.size = CGSize(width: collectionViewFrame.width, height: CGFloat.max)
        let noWiderThanCollectionView = CGRectIntersection(startsAtZero, collectionViewFrame)
        
        return noWiderThanCollectionView.size
    }
}
