//
//  InsettableLabel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/26/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class InsettableLabel: UILabel {
    var insets: UIEdgeInsets = UIEdgeInsetsZero
    
    @IBInspectable var showsBorder: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderWidth = 2
        layer.cornerRadius = 5
        
        // Move this to `init(coder:)` if `insets` ever becomes `@IBInspectable`
        insets = UIEdgeInsetsMake(4, 8, 4, 8)
    }
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        
        size.width += insets.left + insets.right
        size.height += insets.top + insets.bottom
        
        return size
    }
}
