//
//  SegmentedControlCollectionReusableView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SegmentedControlCollectionReusableView: UICollectionReusableView {
    @IBOutlet private(set) weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var blurView: UIVisualEffectView!
    @IBOutlet private weak var bottomLine: UIView!
    @IBOutlet private weak var bottomLineHeightConstraint: NSLayoutConstraint!

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addBlurView()
        addBottomLine()
        addSegmentedControl()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func addBlurView() {
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        blurView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        blurView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        blurView.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
        
        self.blurView = blurView
    }
    
    private func addBottomLine() {
        let bottomLine = UIView()
        addSubview(bottomLine)
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.backgroundColor =  UIColor.lightGrayColor()
        bottomLineHeightConstraint = NSLayoutConstraint(item: bottomLine, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 1.0)
        bottomLine.addConstraint(bottomLineHeightConstraint)
        bottomLine.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        bottomLine.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        bottomLine.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
        
        self.bottomLine = bottomLine
    }
    
    private func addSegmentedControl() {
        let segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentedControl)
        self.segmentedControl = segmentedControl

        let hCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        let vCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)

        let width = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 350)
        width.priority = UILayoutPriorityDefaultLow

        // Greater priority than the width constraint, so it always has at least this margin.
        let leftSide = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 10)
        leftSide.priority = UILayoutPriorityRequired

        addConstraints([hCenter, vCenter, width, leftSide])
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        let scale = window?.screen.scale ?? 1
        bottomLineHeightConstraint.constant = 1 / scale
    }
}
