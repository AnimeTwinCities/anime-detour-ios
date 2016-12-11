//
//  Result.swift
//  Anime Detour
//
//  Created by Brendon Justin on 12/11/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case error(Error)
}
