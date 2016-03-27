//
//  SelectedSessionCategory.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/1/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import AnimeDetourDataModel

enum SelectedSessionCategory: Equatable {
    case All
    case Category(Session.Category)
}

func ==(type1: SelectedSessionCategory, type2: SelectedSessionCategory) -> Bool {
    switch (type1, type2) {
    case (.All, .All):
        return true
    case let (.Category(c1), .Category(c2)):
        return c1 == c2
    default:
        return false
    }
}