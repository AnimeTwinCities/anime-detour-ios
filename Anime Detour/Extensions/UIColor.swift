//
//  UIColor.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/24/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

extension UIColor {
    class var adr_orange: UIColor {
        return UIColor.adr_colorFromHex(0xfe7f00)
    }
    
    /// A lighter version of adr_orange, suitable as a highlight color
    /// as opposed to a tint color.
    // Chosen using http://paletton.com/
    class var adr_lighterOrange: UIColor {
        return UIColor.adr_colorFromHex(0xffb163)
    }

    class var adr_brown: UIColor {
        return UIColor.adr_colorFromHex(0x281200)
    }

    class func adr_colorFromHex(hex: Int) -> UIColor {
        let red = (hex & 0xff0000) >> 16
        let green = (hex & 0xff00) >> 8
        let blue = (hex & 0xff)

        let rNorm = CGFloat(red) / 255
        let bNorm = CGFloat(blue) / 255
        let gNorm = CGFloat(green) / 255
        return UIColor(red: rNorm, green: gNorm, blue: bNorm, alpha: 1)
    }
}