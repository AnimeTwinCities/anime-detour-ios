//
//  FilmstripsFlowLayout.swift
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
public class FilmstripsFlowLayout: UICollectionViewLayout {
    public var itemSize: CGSize = CGSizeZero
    public var minimumLineSpacing: CGFloat = 0
    public var minimumInteritemSpacing: CGFloat = 0
    public var headerReferenceSize: CGSize = CGSizeZero

    /// Dictionary of section numbers to scroll offsets
    private var cumulativeOffsets: [Int : CGFloat] = [:]
    private var currentPanOffsets: [Int : CGFloat] = [:]
    private var sectionDynamicItems: [Int : SectionDynamicItem] = [:]
    private var sectionDynamicBehaviors: [Int : [UIDynamicBehavior]] = [:]
    private var springsForFirstItems: [Int : UISnapBehavior] = [:]
    private var springsForLastItems: [Int : UISnapBehavior] = [:]
    lazy private var positiveRect = CGRect(x: 0, y: 0, width: Int.max, height: Int.max)
    
    /// Animator to animate horizontal cell scrolling
    lazy private var dynamicAnimator: UIDynamicAnimator = UIDynamicAnimator()
    
    private var sectionHeightWithSpacing: CGFloat {
        get {
            let size = self.itemSize
            let lineSpacing = self.minimumLineSpacing
            let headerSize = self.headerReferenceSize
            
            let sectionHeight = headerSize.height + lineSpacing + size.height + lineSpacing
            return sectionHeight
        }
    }

    private var cellWidthWithSpacing: CGFloat {
        get {
            let size = self.itemSize
            let itemWidth = size.width
            let layoutWidth = self.collectionView!.frame.width
            let cellSpacing = self.minimumInteritemSpacing
            let widthPlusPaddingPerCell = itemWidth + cellSpacing

            return widthPlusPaddingPerCell
        }
    }
    
    // MARK: Collection View Layout
    
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let positiveRect = rect.rectByIntersecting(self.positiveRect)
        let cellWidthWithSpacing = self.cellWidthWithSpacing

        let sectionsBeforeRect = self.section(forYCoordinate: positiveRect.minY)
        let lastPossibleSectionInRect = self.section(forYCoordinate: positiveRect.maxY)
        
        let totalSections = self.collectionView?.numberOfSections() ?? 0
        if totalSections == 0 {
            return []
        }
        
        let firstSectionInRect = Int(min(sectionsBeforeRect, totalSections - 1))
        let lastSectionInRect = Int(min(totalSections, lastPossibleSectionInRect))
        let sectionsInRect = firstSectionInRect..<lastSectionInRect
        
        let maxItemsPerSectionInRect = Int(ceil(positiveRect.width / cellWidthWithSpacing))
        
        let itemsPerSectionInRect: [Int : [Int]] = { () -> [Int : [Int]] in
            var itemSectionsAndNumbers = [Int : [Int]]()
            
            for section in sectionsInRect {
                let scrollOffsetForSection = self.totalOffset(forSection: section)
                let xOffsetForFirstItem: CGFloat = floor(positiveRect.minX / ceil(cellWidthWithSpacing))
                
                let itemsInSection = self.collectionView?.numberOfItemsInSection(section) ?? 0
                
                let firstPossibleItemInRect = Int(ceil(positiveRect.minX / max(xOffsetForFirstItem, CGFloat(1))))
                let firstItemInRect = Int(min(itemsInSection, firstPossibleItemInRect))
                
                var itemNumbers = [Int]()
                for itemNumber in firstItemInRect..<itemsInSection {
                    let xOffsetForItemNumber: CGFloat = ceil(cellWidthWithSpacing * CGFloat(itemNumber)) + xOffsetForFirstItem
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
            // Assume section headers are present if the header reference size is set.
            if self.headerReferenceSize != CGSizeZero {
                attributes.append(self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: section)))
            }

            for itemNumber in itemNumbers {
                attributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: itemNumber, inSection: section)))
            }
        }
        
        return attributes
    }
    
    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attributes.frame = { () -> CGRect in
            let size = self.itemSize
            let headerSize = self.headerReferenceSize

            let xOffsetForItemNumber: CGFloat = ceil(self.cellWidthWithSpacing * CGFloat(indexPath.item))
            let yOffsetForSectionNumber: CGFloat = ceil(self.sectionHeightWithSpacing * CGFloat(indexPath.section))

            let section = indexPath.section
            let frame = CGRect(origin: CGPoint(x: xOffsetForItemNumber + self.totalOffset(forSection: section), y: headerSize.height + yOffsetForSectionNumber), size: size)
            return frame
        }()
        
        return attributes
    }

    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        attributes.frame = { () -> CGRect in
            let size = self.headerReferenceSize
            let yOffsetForSectionNumber: CGFloat = ceil(self.sectionHeightWithSpacing * CGFloat(indexPath.section))

            let section = indexPath.section
            let frame = CGRect(origin: CGPoint(x: 0, y: yOffsetForSectionNumber), size: size)
            return frame
        }()

        return attributes
    }
    
    override public func collectionViewContentSize() -> CGSize {
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

        var collectionViewFrame = self.collectionView?.frame ?? CGRectZero
        var cvHeight = collectionViewFrame.height
        var cvWidth = collectionViewFrame.width
        let contentHeight = max(CGFloat(numberOfSections) * self.sectionHeightWithSpacing, cvHeight)
        let contentFrame = CGRect(origin: CGPointZero, size: CGSize(width: cvWidth, height: contentHeight))

        let widthLimitingFrame = CGRect(origin: CGPointZero, size: CGSize(width: collectionViewFrame.width, height: CGFloat.max))
        let widthLimitedContentFrame = CGRectIntersection(contentFrame, widthLimitingFrame)
        
        return widthLimitedContentFrame.size
    }

    public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: Offset Calculation

    private func totalOffset(forSection section: Int) -> CGFloat {
        let cumulativeOffset = self.cumulativeOffsets[section] ?? 0
        let panOffset = self.currentPanOffsets[section] ?? 0

        return cumulativeOffset + panOffset
    }
    
    // MARK: Section and Item/Row Calculation
    
    /**
    Find the section number corresponding to a Y-coordinate in the collection view.
    May be greater than the actual number of sections in the collection view.
    */
    private func section(forYCoordinate coordinate: CGFloat) -> Int {
        let sectionHeight = self.sectionHeightWithSpacing
        let sectionForCoordinate = Int(floor(coordinate / sectionHeight))
        
        return sectionForCoordinate
    }

    /**
    Get the item number that should appear at the specified coordinate.
    :param: forXCoordinate The X coordinate for which to get the item
    */
    private func itemNumber(forXCoordinate coordinate: CGFloat, inSection section: Int) -> Int {
        let itemForCoordinate = Int(floor(coordinate / self.cellWidthWithSpacing))

        return itemForCoordinate
    }

    /**
    Get the index paths corresponding to all items in a section that are currently
    or are close to being displayed, e.g. the items that are just outside of the frame.
    */
    private func indexPathsCurrentlyDisplayed(inSection section: Int) -> [NSIndexPath] {
        let xOffset = self.totalOffset(forSection: section)
        let minXCoordinate = -xOffset
        let itemWidth = self.itemSize.width
        let collectionViewWidth = self.collectionView!.frame.width
        let firstDisplayedItem = self.itemNumber(forXCoordinate: minXCoordinate, inSection: section)
        let lastDisplayedItem = self.itemNumber(forXCoordinate: minXCoordinate + collectionViewWidth + itemWidth, inSection: section)
        let lastItemInSection = self.collectionView!.numberOfItemsInSection(section)

        let firstItem = max(firstDisplayedItem - 1, 0)
        let lastItem = max(min(lastDisplayedItem + 1, lastItemInSection), firstItem)

        let paths = (firstItem...lastItem).map { (itemNumber: Int) -> NSIndexPath in
            return NSIndexPath(forItem: itemNumber, inSection: section)
        }

        return paths
    }

    private func width(ofSection sectionNumber: Int) -> CGFloat {
        let itemsInSection = self.collectionView!.numberOfItemsInSection(sectionNumber)
        return CGFloat(itemsInSection) * self.cellWidthWithSpacing
    }

    // MARK: Dynamics

    private func addSpringsAsNecessary(toDynamicItem sectionDynamicItem: SectionDynamicItem, forOffset offset: CGFloat, inSection sectionNumber: Int) {
        if (offset > 0) {
            if let behavior = self.springsForFirstItems[sectionNumber] {
                // empty
            } else {
                let springBehavior = UISnapBehavior(item: sectionDynamicItem, snapToPoint: CGPoint(x: 0, y: sectionDynamicItem.center.y))!
                springBehavior.damping = 0.75
                self.springsForFirstItems[sectionNumber] = springBehavior
                self.dynamicAnimator.addBehavior(springBehavior)
            }
        }

        let collectionView = self.collectionView!
        let viewWidth = collectionView.frame.width
        let widthOfSection = self.width(ofSection: sectionNumber)
        let rightSideSnapXCoord: CGFloat = {
            if viewWidth > widthOfSection {
                return 0
            } else {
                return -(widthOfSection - collectionView.frame.width)
            }
        }()
        if (offset < rightSideSnapXCoord) {
            if let behavior = self.springsForLastItems[sectionNumber] {
                // empty
            } else {
                let springBehavior = UISnapBehavior(item: sectionDynamicItem, snapToPoint: CGPoint(x: rightSideSnapXCoord, y: sectionDynamicItem.center.y))!
                springBehavior.damping = 0.75
                self.springsForLastItems[sectionNumber] = springBehavior
                self.dynamicAnimator.addBehavior(springBehavior)
            }
        }
    }

    private func dynamicItem(forSection sectionNumber: Int) -> SectionDynamicItem {
        if let sectionItem = self.sectionDynamicItems[sectionNumber] {
            return sectionItem
        } else {
            let sectionItem = SectionDynamicItem(sectionNumber: sectionNumber)
            return sectionItem
        }
    }

    // MARK: Pan Gesture Action

    /**
    Receive a pan gesture to pan the items in a row. The pan must take place within our collection view's frame.
    */
    @IBAction func pan(recognizer: UIPanGestureRecognizer) {
        let collectionView = self.collectionView!
        let collectionViewLocation = recognizer.locationInView(collectionView)
        
        let sectionOfPan = self.section(forYCoordinate: collectionViewLocation.y)
        let translation = recognizer.translationInView(collectionView)

        // Update the amount of panning done
        let currentPanOffset = translation.x
        self.currentPanOffsets[sectionOfPan] = currentPanOffset

        let indexPaths = self.indexPathsCurrentlyDisplayed(inSection: sectionOfPan)
        let context = UICollectionViewLayoutInvalidationContext()
        context.invalidateItemsAtIndexPaths(indexPaths)
        self.invalidateLayoutWithContext(context)

        let newCumulativeOffset = self.totalOffset(forSection: sectionOfPan)

        let sectionDynamicItem = self.dynamicItem(forSection: sectionOfPan)
        sectionDynamicItem.center = CGPoint(x: newCumulativeOffset, y: 0)
        self.sectionDynamicItems[sectionOfPan] = sectionDynamicItem

        if recognizer.state == .Ended {
            self.cumulativeOffsets[sectionOfPan] = newCumulativeOffset
            self.currentPanOffsets[sectionOfPan] = nil

            let velocity = recognizer.velocityInView(self.collectionView)

            sectionDynamicItem.delegate = self
            let items = [sectionDynamicItem]
            let behavior = UIPushBehavior(items: items, mode: .Instantaneous)
            behavior.pushDirection = CGVector(dx: velocity.x > 0 ? 1 : -1, dy: 0)
            behavior.magnitude = abs(velocity.x)

            let resistance = UIDynamicItemBehavior(items: items)
            resistance.resistance = 1

            self.dynamicAnimator.addBehavior(behavior)
            self.dynamicAnimator.addBehavior(resistance)
            self.sectionDynamicBehaviors[sectionOfPan] = [behavior, resistance]
        } else {
            if let behaviors = self.sectionDynamicBehaviors.removeValueForKey(sectionOfPan) {
                for behavior in behaviors {
                    self.dynamicAnimator.removeBehavior(behavior)
                }
            }

            if let snapbehavior = self.springsForFirstItems.removeValueForKey(sectionOfPan) {
                self.dynamicAnimator.removeBehavior(snapbehavior)
            }
            if let snapbehavior = self.springsForLastItems.removeValueForKey(sectionOfPan) {
                self.dynamicAnimator.removeBehavior(snapbehavior)
            }

            sectionDynamicItem.delegate = nil
            self.addSpringsAsNecessary(toDynamicItem: sectionDynamicItem, forOffset: newCumulativeOffset, inSection: sectionOfPan)
        }
    }
}

extension FilmstripsFlowLayout: SectionDynamicItemDelegate {
    internal func itemDidMove(sectionDynamicItem: SectionDynamicItem) {
        let newCenter = sectionDynamicItem.center
        let sectionNumber = sectionDynamicItem.sectionNumber
        let cumulativeOffset = (self.currentPanOffsets[sectionNumber] ?? 0) + newCenter.x
        self.cumulativeOffsets[sectionNumber] = cumulativeOffset

        self.addSpringsAsNecessary(toDynamicItem: sectionDynamicItem, forOffset: cumulativeOffset, inSection: sectionNumber)

        let indexPaths = self.indexPathsCurrentlyDisplayed(inSection: sectionNumber)

        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateItemsAtIndexPaths(indexPaths)
        self.invalidateLayoutWithContext(context)
    }
}

