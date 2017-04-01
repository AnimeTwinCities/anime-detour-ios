//
//  FlowLayoutContaining.swift
//  DevFest
//
//  Created by Brendon Justin on 11/29/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 Note: The item sizes in storyboards are often set to `320`, the narrowest width
 that we expect a view controller to ever be. If it is set higher,
 when the app is run on a narrow device such as the iPhone SE,
 collection view cells start out wider than the collection view.
 This is undefined behavior and results in poor behavior on iOS 10.
 */
protocol FlowLayoutContaining {
    var flowLayout: UICollectionViewFlowLayout! { get }
    var view: UIView! { get }
    
    func updateFlowLayoutItemWidth(viewSize size: CGSize?)
}

extension FlowLayoutContaining where Self: UIViewController {
    // MARK: - Default implementations
    
    func updateFlowLayoutItemWidth(viewSize size: CGSize? = nil) {
        let width = size?.width ?? view.frame.width
        flowLayout?.itemSize.width = width
        
        // Having just updated our item sizes, our collection view layout object's layout is now invalid.
        // Let it know that this is the case.
        self.flowLayout?.invalidateLayout()
    }
    
    // MARK: - Statically dispatched methods
    
    func updateLayoutOnTransition(toViewSize size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayoutItemWidth(viewSize: size)
        
        coordinator.animate(alongsideTransition: { context in
            // Ask for a layout. If we don't ask for a layout, and we transition to a different size while
            // we're not visible, the size transition will animate the next time we become visible.
            // Asking for a layout now ensures that the animation happens alongside the size transition,
            // or not at all.
            self.view.layoutIfNeeded()
        } , completion: nil)
    }
}
