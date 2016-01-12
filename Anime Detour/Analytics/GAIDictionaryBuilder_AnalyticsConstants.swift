//
//  GAIDictionaryBuilder_AnalyticsConstants.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/11/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import Foundation

extension GAIDictionaryBuilder {
    static func createEventDictionary(category: String, action: AnalyticsConstants.Actions, label: String?, value: NSNumber?) -> [NSObject : AnyObject] {
        let dict = GAIDictionaryBuilder.createEventWithCategory(category, action: action.rawValue, label: label, value: value).build() as NSDictionary as [NSObject : AnyObject]
        return dict
    }
    
    static func createEventDictionary(category: AnalyticsConstants.Category, action: AnalyticsConstants.Actions, label: String?, value: NSNumber?) -> [NSObject : AnyObject] {
        let dict = GAIDictionaryBuilder.createEventDictionary(category.rawValue, action: action, label: label, value: value)
        return dict
    }
}
