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
