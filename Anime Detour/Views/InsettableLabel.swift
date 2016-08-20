//
//  InsettableLabel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/26/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class InsettableLabel: UILabel {
    var insets: UIEdgeInsets = .zero
    
    @IBInspectable var showsBorder: Bool = false
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        size.width += insets.left + insets.right
        size.height += insets.top + insets.bottom
        
        return size
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderWidth = 2
        layer.cornerRadius = 5
        
        // Move this to `init(coder:)` if `insets` ever becomes `@IBInspectable`
        insets = UIEdgeInsetsMake(4, 8, 4, 8)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
