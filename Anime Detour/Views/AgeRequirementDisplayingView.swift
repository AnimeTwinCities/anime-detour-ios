//
//  AgeRequirementDisplayingView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/28/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import Aspects

private let backgroundColor = UIColor.adr_colorFromHex(0xE53935)
private let textColor = UIColor.white

protocol AgeRequirementDisplayingView {
    var ageRequirementLabel: InsettableLabel! { get }
    
    /// Any `UIView` subclass conforming to this protocol will be made to call this method
    /// in `awakeFromNib` via Aspects if , so storyboard-created views need not call it.
    func updateAgeRequirementLabelAppearance()
    func showAgeRequirementOrHideLabel(forViewModel viewModel: SessionViewModel?)
}

extension AgeRequirementDisplayingView {
    func updateAgeRequirementLabelAppearance() {
        setAgeRequirementLabelBackgroundColor()
        ageRequirementLabel.textColor = textColor
        let ageLayer = ageRequirementLabel.layer
        ageLayer.borderColor = backgroundColor.cgColor
        ageLayer.masksToBounds = true
    }
    
    func showAgeRequirementOrHideLabel(forViewModel viewModel: SessionViewModel?) {
        let ageRequirement: String
        let ageRequirementHidden: Bool
        if viewModel?.is18Plus ?? false {
            ageRequirement = "18+"
            ageRequirementHidden = false
        } else if viewModel?.is21Plus ?? false {
            ageRequirement = "21+"
            ageRequirementHidden = false
        } else {
            ageRequirement = ""
            ageRequirementHidden = true
        }
        ageRequirementLabel.text = ageRequirement
        ageRequirementLabel.isHidden = ageRequirementHidden
    }
    
    fileprivate func setAgeRequirementLabelBackgroundColor() {
        ageRequirementLabel.backgroundColor = backgroundColor
    }
}

class AgeRequirementAwakeFromNibHook {
    static func hookAwakeFromNibForAgeLabelAppearance() {
        let block: @convention(block) (_ info: AspectInfo) -> Void = { info in
            guard let ageRequirementView = info.instance() as? AgeRequirementDisplayingView else {
                return
            }
            
            ageRequirementView.updateAgeRequirementLabelAppearance()
        }
        // lol type-safety
        let objBlock = unsafeBitCast(block, to: AnyObject.self)
        
        do {
            try UIView.aspect_hook(#selector(UIView.awakeFromNib), with:AspectOptions(), usingBlock: objBlock)
        } catch {
            NSLog("Error hooking UIView.awakeFromNib for age displaying labels: %@", error as NSError)
        }
    }
    
    static func hookTableViewCellSetHighlightedForAgeLabelAppearance() {
        let block: @convention(block) (_ info: AspectInfo, _ highlighted: Bool, _ animated: Bool) -> Void = { info, _, _ in
            guard let ageRequirementView = info.instance() as? AgeRequirementDisplayingView else {
                return
            }
            
            ageRequirementView.setAgeRequirementLabelBackgroundColor()
        }
        // lol type-safety
        let objBlock = unsafeBitCast(block, to: AnyObject.self)
        
        do {
            try UITableViewCell.aspect_hook(#selector(UITableViewCell.setHighlighted(_:animated:)), with:AspectOptions(), usingBlock: objBlock)
        } catch {
            NSLog("Error hooking UITableViewCell.setHighlighted:animated: for age displaying labels: %@", error as NSError)
        }
    }
    
    static func hookTableViewCellSetSelectedForAgeLabelAppearance() {
        let block: @convention(block) (_ info: AspectInfo, _ selected: Bool, _ animated: Bool) -> Void = { info, _, _ in
            guard let ageRequirementView = info.instance() as? AgeRequirementDisplayingView else {
                return
            }
            
            ageRequirementView.setAgeRequirementLabelBackgroundColor()
        }
        // lol type-safety
        let objBlock = unsafeBitCast(block, to: AnyObject.self)
        
        do {
            try UITableViewCell.aspect_hook(#selector(UITableViewCell.setSelected(_:animated:)), with:AspectOptions(), usingBlock: objBlock)
        } catch {
            NSLog("Error hooking UITableViewCell.setSelected:animated: for age displaying labels: %@", error as NSError)
        }
    }
}
