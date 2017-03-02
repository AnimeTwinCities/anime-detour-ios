//
//  UIView+DevFest.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

extension UIView {
    /**
     Add `view` and set its `translatesAutoResizingMaskIntoConstraints` at the same time.
     `translatesAutoResizingMaskIntoConstraints` is `false` by default.
     */
    func dev_addSubview(_ view: UIView, translatesAutoresizingMaskIntoConstraints: Bool = false) {
        view.translatesAutoresizingMaskIntoConstraints = translatesAutoresizingMaskIntoConstraints
        addSubview(view)
    }
    
    /**
     Constrain `self` to its `superview`'s edges.
     
     - parameter shouldActivate: `true` to activate constraints. `true` by default.
     */
    @discardableResult
    func dev_constrainToSuperEdges(shouldActivate: Bool = true) -> [NSLayoutConstraint] {
        guard let containing = superview else {
            assertionFailure("Must have a superview to constrain our edges to it.")
            return []
        }
        
        let superConstraints: [NSLayoutConstraint] = [
            leadingAnchor.constraint(equalTo: containing.leadingAnchor),
            topAnchor.constraint(equalTo: containing.topAnchor),
            trailingAnchor.constraint(equalTo: containing.trailingAnchor),
            bottomAnchor.constraint(equalTo: containing.bottomAnchor),
            ]
        
        for constraint in superConstraints {
            constraint.identifier = "dev_constrainToSuperMargins constraint"
        }
        
        if shouldActivate {
            NSLayoutConstraint.activate(superConstraints)
        }
        
        return superConstraints
    }
    
    /**
     Constrain `self` to its `superview`'s margins.
     
     - parameter shouldActivate: `true` to activate constraints. `true` by default.
     */
    @discardableResult
    func dev_constrainToSuperMargins(shouldActivate: Bool = true) -> [NSLayoutConstraint] {
        guard let containing = superview else {
            assertionFailure("Must have a superview to constrain our edges to it.")
            return []
        }
        
        let superConstraints: [NSLayoutConstraint] = [
            leadingAnchor.constraint(equalTo: containing.layoutMarginsGuide.leadingAnchor),
            topAnchor.constraint(equalTo: containing.layoutMarginsGuide.topAnchor),
            trailingAnchor.constraint(equalTo: containing.layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: containing.layoutMarginsGuide.bottomAnchor),
            ]
        
        for constraint in superConstraints {
            constraint.identifier = "dev_constrainToSuperMargins constraint"
        }
        
        if shouldActivate {
            NSLayoutConstraint.activate(superConstraints)
        }
        
        return superConstraints
    }
}
