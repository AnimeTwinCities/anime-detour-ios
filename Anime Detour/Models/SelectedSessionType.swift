//
//  SelectedSessionType.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/1/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

enum SelectedSessionType: Equatable {
    case All
    case Named(String)
}

func ==(type1: SelectedSessionType, type2: SelectedSessionType) -> Bool {
    switch (type1, type2) {
    case (.All, .All):
        return true
    case let (.Named(name1), .Named(name2)):
        return name1 == name2
    default:
        return false
    }
}