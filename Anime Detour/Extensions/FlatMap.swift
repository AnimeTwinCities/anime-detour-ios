//
//  FlatMap.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/11/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

extension Array {
    /**
    Call `transform` on each element, then concatenate
    all of the resulting arrays into one array.
    */
    func flatMap<U>(transform: T -> [U]) -> [U] {
        var results = [U]()
        for arr in self.map(transform) {
            results.extend(arr)
        }

        return results
    }
}

extension Optional {
    /**
    If `self` is not `nil`, call `transform(self!)`.
    If the result is not `nil`, return it. Else return `nil`.
    */
    func flatMap<U>(transform: T -> U?) -> U? {
        return self.map(transform) ?? nil
    }
}
