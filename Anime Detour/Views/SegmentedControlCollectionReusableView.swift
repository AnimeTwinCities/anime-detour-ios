//
//  SegmentedControlCollectionReusableView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SegmentedControlCollectionReusableView: UICollectionReusableView {
    @IBOutlet private(set) var segmentedControl: UISegmentedControl!

    convenience init() {
        self.init(frame: CGRect.zeroRect)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSegmentedControl()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func addSegmentedControl() {
        let segmentedControl = UISegmentedControl()
        segmentedControl.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(segmentedControl)
        self.segmentedControl = segmentedControl

        let hCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        let vCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)

        let width = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 350)
        width.priority = 250 // UILayoutPriorityDefaultLow

        // Greater priority than the width constraint, so it always has at least this margin.
        let leftSide = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 10)
        leftSide.priority = 1000 // UILayoutPriorityRequired

        // NOTE: UILayoutPriority constants cause linker errors, so don't use them

        self.addConstraints([hCenter, vCenter, width, leftSide])
    }
}
