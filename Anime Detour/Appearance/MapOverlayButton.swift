//
//  MapOverlayButton.swift
//  DevFest
//
//  Created by Brendon Justin on 12/4/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 A view that acts like a button, meant to be used over a map view.
 */
@IBDesignable
class MapOverlayButton: UIView {
    let button = UIButton(type: .system)
    
    /**
     The action to run when the button is used.
     */
    var action: () -> Void = {}
    
    fileprivate var cornerRadius: CGFloat {
        return .dev_standardMargin * 0.7
    }
    
    override var intrinsicContentSize: CGSize {
        let buttonSize = button.intrinsicContentSize
        return buttonSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // don't add the button yet, since this is the init method used by
        // IB for IBDesignable views, and it doesn't like adding subviews in init.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addButton()
        dev_updateAppearance()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        addButton()
        dev_updateAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        // Set a background color only on the button, so the button's rounded corners show.
        backgroundColor = .clear
        button.backgroundColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: .dev_standardMargin, left: .dev_standardMargin, bottom: .dev_standardMargin, right: .dev_standardMargin)
        
        let buttonLayer = button.layer
        buttonLayer.cornerRadius = cornerRadius
        buttonLayer.masksToBounds = true

        layer.shadowColor = UIColor.dev_shadowColor.cgColor
        layer.shadowOffset = .dev_shadowOffset
        layer.shadowOpacity = .dev_shadowOpacity
        layer.shadowRadius = .dev_shadowRadius
        updateShadowPath()
    }
}

private extension MapOverlayButton {
    @objc func runAction() {
        action()
    }
    
    func addButton() {
        dev_addSubview(button)
        button.dev_constrainToSuperEdges()
        
        button.setTitle(NSLocalizedString("Re-center", comment: "Re-center the map on the conference venue"), for: .normal)
        
        button.addTarget(self, action: #selector(runAction), for: .touchUpInside)
    }
    
    func updateShadowPath() {
        let shadowPath = CGPath(roundedRect: bounds,
                                cornerWidth: cornerRadius,
                                cornerHeight: cornerRadius,
                                transform: nil)
        layer.shadowPath = shadowPath
    }
}
