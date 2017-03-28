//
//  SegmentedControlCollectionReusableView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class SegmentedControlCollectionReusableView: UICollectionReusableView {
    static var reuseID: String {
        return String(describing: SegmentedControlCollectionReusableView.self)
    }
    
    @IBOutlet fileprivate(set) weak var segmentedControl: UISegmentedControl!
    @IBOutlet fileprivate weak var blurView: UIVisualEffectView!
    @IBOutlet fileprivate weak var bottomLine: UIView!
    @IBOutlet fileprivate weak var bottomLineHeightConstraint: NSLayoutConstraint!

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

    fileprivate func addBlurView() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        blurView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        blurView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        blurView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        self.blurView = blurView
    }
    
    fileprivate func addBottomLine() {
        let bottomLine = UIView()
        addSubview(bottomLine)
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.backgroundColor =  UIColor.lightGray
        bottomLineHeightConstraint = NSLayoutConstraint(item: bottomLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0)
        bottomLine.addConstraint(bottomLineHeightConstraint)
        bottomLine.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomLine.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        self.bottomLine = bottomLine
    }
    
    fileprivate func addSegmentedControl() {
        let segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentedControl)
        self.segmentedControl = segmentedControl

        let hCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0)
        let vCenter = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0)

        let width = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 350)
        width.priority = UILayoutPriorityDefaultLow

        // Greater priority than the width constraint, so it always has at least this margin.
        let leftSide = NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 10)
        leftSide.priority = UILayoutPriorityRequired

        addConstraints([hCenter, vCenter, width, leftSide])
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        let scale = window?.screen.scale ?? 1
        bottomLineHeightConstraint.constant = 1 / scale
    }
}

extension SegmentedControlCollectionReusableView: ReusableItem {}
