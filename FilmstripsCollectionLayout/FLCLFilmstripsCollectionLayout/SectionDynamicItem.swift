//
//  SectionDynamicItem.swift
//  FilmstripsCollectionLayout
//
//  Created by Brendon Justin on 10/26/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

internal protocol SectionDynamicItemDelegate: NSObjectProtocol {
    func itemDidMove(sectionDynamicItem: SectionDynamicItem)
}

/**
Placeholder dynamic item whose sole purpose is to keep track of the scroll offset for a given section.
*/
internal class SectionDynamicItem: NSObject, UIDynamicItem {
    /// The location and size of the item. 1000x1000 is the size to get 1 pt/s^2 acceleration for
    /// a magnitude 1 push behavior.
    var bounds: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1000, height: 1000))
    var center: CGPoint = CGPointZero {
        didSet {
            self.delegate?.itemDidMove(self)
        }
    }
    var transform: CGAffineTransform = CGAffineTransformIdentity

    let sectionNumber: Int
    weak var delegate: SectionDynamicItemDelegate?

    init(sectionNumber: Int) {
        self.sectionNumber = sectionNumber
        super.init()
    }
}