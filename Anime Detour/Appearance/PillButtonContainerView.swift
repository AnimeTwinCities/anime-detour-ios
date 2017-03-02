//
//  PillButtonContainerView.swift
//  DevFest
//
//  Created by Brendon Justin on 1/28/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 A view that contains a button and gives that button a pill-like appearance.
 
 If instantiating via IB, add a button and set it to the `button` outlet yourself.
 */
@IBDesignable
class PillButtonContainerView: UIView {
    private static let minimumWidth: CGFloat = 100
    @IBOutlet var button: UIButton!
    
    override var intrinsicContentSize: CGSize {
        guard let buttonSize = button?.intrinsicContentSize else {
            return CGSize(width: 10, height: PillButtonContainerView.minimumWidth)
        }
        
        var minWidthButtonSize = buttonSize
        if case let minWidth = PillButtonContainerView.minimumWidth, minWidthButtonSize.width < minWidth {
            minWidthButtonSize.width = minWidth
        }
        
        return minWidthButtonSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button = UIButton(type: .system)
        dev_addSubview(button)
        button.dev_constrainToSuperEdges()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        dev_updateAppearance()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        button.titleLabel?.font = .dev_pillButtonTitleFont
        
        let verticalMargin: CGFloat = .dev_standardMargin
        let horizontalMargin: CGFloat = .dev_standardMargin * 2
        button.contentEdgeInsets = UIEdgeInsetsMake(verticalMargin, horizontalMargin, verticalMargin, horizontalMargin)
        if let _ = button.image(for: .normal) {
            let buttonHorizontalMargin = CGFloat.dev_standardMargin / 2
            button.imageEdgeInsets = UIEdgeInsetsMake(0, -buttonHorizontalMargin, 0, buttonHorizontalMargin)
            button.titleEdgeInsets = UIEdgeInsetsMake(0, buttonHorizontalMargin, 0, -buttonHorizontalMargin)
        } else {
            button.imageEdgeInsets = .zero
            button.titleEdgeInsets = .zero
        }
        
        let backgroundImage = makeButtonBackground().withRenderingMode(.alwaysTemplate)
        button.setBackgroundImage(backgroundImage, for: .normal)
    }
    
    /**
     Make a roundRect suitable for use as our button's background.
     */
    private func makeButtonBackground() -> UIImage {
        let cornerRadius = CGFloat.dev_pillButtonCornerRadius
        
        let lineThickness = 1 * contentScaleFactor
        let strokeColor = UIColor.black
        
        // Add extra size between the corners that can be stretched as necessary.
        let size = CGSize(width: cornerRadius * 2 + 1, height: cornerRadius * 2 + 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(lineThickness)
        
        let rect = CGRect(origin: .zero, size: size)
        // Inset the rect by half of the line thickness so the path is entirely inside
        // the size we gave. Skipping this step would mean half of our drawn path would be outside
        // of the size we gave, resulting in a very ugly path.
        let insetRect = rect.insetBy(dx: lineThickness / 2, dy: lineThickness / 2)
        let roundedRect = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius)
        let roundedRectPath = roundedRect.cgPath
        
        context.addPath(roundedRectPath)
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        let stretchableImage = image.resizableImage(withCapInsets: UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius))
        return stretchableImage
    }
}
