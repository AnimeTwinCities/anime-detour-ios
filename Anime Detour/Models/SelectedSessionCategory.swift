//
//  SelectedSessionCategory.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/1/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

enum SelectedSessionCategory: Equatable {
    case all
    case category(SessionViewModel.Category)
}

func ==(type1: SelectedSessionCategory, type2: SelectedSessionCategory) -> Bool {
    switch (type1, type2) {
    case (.all, .all):
        return true
    case let (.category(c1), .category(c2)):
        return c1 == c2
    default:
        return false
    }
}
