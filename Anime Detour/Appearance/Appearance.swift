//
//  Appearance.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import CoreGraphics
import UIKit

struct Appearance {
    /// Setup default appearances via appearance proxies
    static func setupAppearanceProxies() {
        let mainColor = UIColor.adr_orange
        
        UIApplication.shared.keyWindow?.tintColor = mainColor
        
        // Setup the appearance of age requirement labels
        AgeRequirementAwakeFromNibHook.hookAwakeFromNibForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetHighlightedForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetSelectedForAgeLabelAppearance()
        
        // Make UISearchBars minimal style but with gray text fields by default
        let searchBar = UISearchBar.appearance()
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = UIColor.adr_lightGray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.gray
        
        let tableViewBackgroundView = UIView()
        tableViewBackgroundView.backgroundColor = UIColor.adr_lighterOrange
        UITableViewCell.appearance().selectedBackgroundView = tableViewBackgroundView
        SpeakerCell.appearance().highlightColor = UIColor.adr_lighterOrange
        SessionCell.appearance().highlightColor = UIColor.adr_lighterOrange
        SessionHeaderCollectionReusableView.appearance().backgroundColor = UIColor.adr_lightGray
    }
}

// All other things appearance, e.g. colors, margins, sizes

extension CGFloat {
    /**
     The horizontal margin to use for content-y views.
     */
    static let dev_contentHorizontalMargin: CGFloat = .dev_standardMargin * 2
    
    /**
     The vertical margin to use in between content-y views.
     */
    static let dev_contentInsideVerticalMargin: CGFloat = .dev_standardMargin * 2
    
    /**
     The vertical margin to use on the outside edges of content-y views.
     */
    static let dev_contentOutsideVerticalMargin: CGFloat = .dev_standardMargin * 3
    
    static let dev_pillButtonCornerRadius: CGFloat = (CGFloat.dev_standardMargin * 1.33).rounded()
    
    /**
     The usual margin to use when space between two items is needed.
     */
    static let dev_standardMargin: CGFloat = 8
    
    /**
     A smaller margin to use for space between items.
     */
    static let dev_tightMargin: CGFloat = .dev_standardMargin / 2
    
    // Rounding is important for sizes meant to be used for views.
    static let dev_authorPhotoSideLength: CGFloat = (CGFloat.dev_standardMargin * 7).rounded()
    
    static let dev_shadowRadius: CGFloat = 5
    
    static var dev_trackLabelHeight: CGFloat {
        // Base the height of the track label, plus its extra margin, on the label's font size.
        let font = UIFont.dev_sessionCategoryFont
        let fontSize = font.pointSize
        return fontSize + .dev_standardMargin * 2
    }
}

extension CGSize {
    static var dev_shadowOffset: CGSize = CGSize(width: 0, height: 2)
}

extension Float {
    static var dev_shadowOpacity: Float = 0.5
}

extension UIColor {
    @nonobjc static let dev_sessionHeaderBackgroundColor: UIColor = UIColor(red: 0xf5 / 255, green: 0xf5 / 255, blue: 0xf5 / 255, alpha: 1)
    
    @nonobjc static let dev_shadowColor: UIColor = .gray

    @nonobjc static let dev_sessionSpeakersBackgroundColor: UIColor = .dev_sessionHeaderBackgroundColor
}

extension UIEdgeInsets {
    static let dev_standardMargins: UIEdgeInsets = UIEdgeInsets(top: .dev_standardMargin, left: .dev_standardMargin, bottom: .dev_standardMargin, right: .dev_standardMargin)
}

// These must be `static var`s instead of `static let`s since they can change
// if the user changes their font settings device-wide.
extension UIFont {
    
    /**
     Meant for use on body copy, i.e. longer text.
     */
    static var dev_contentFont: UIFont {
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let font = baseFont.withSize(baseFont.pointSize - 2)
        return font
    }
    
    static var dev_pillButtonTitleFont: UIFont {
        let regularFont = UIFont.preferredFont(forTextStyle: .body)
        let baseSize = regularFont.pointSize
        return UIFont.systemFont(ofSize: baseSize - 2)
    }
    
    static var dev_reusableItemTitleFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    static var dev_reusableItemSubtitleFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    static var dev_sectionHeaderFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .title3)
    }
    
    static var dev_sessionCategoryFont: UIFont {
        let baseFont = UIFont.preferredFont(forTextStyle: .footnote)
        let categoryFont = UIFont.boldSystemFont(ofSize: baseFont.pointSize)
        return categoryFont
    }
    
    static var dev_sessionLocationFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    static var dev_sessionSpeakersTitleFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    static var dev_sessionTitleFont: UIFont {
        return .dev_reusableItemTitleFont
    }
    
    static var dev_sessionTimeFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    static var dev_sessionTimeHeaderFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }
    
    static var dev_speakerNameFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }
    
    static var dev_speakerCompanyFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }
}
