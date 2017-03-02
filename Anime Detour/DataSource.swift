//
//  DataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/22/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

/**
 Protocol for table- or collection-view style data sources.
 */
protocol DataSource {
    var numberOfSections: Int { get }
    func title(forSection section: Int) -> String?
    func numberOfItems(inSection section: Int) -> Int
}
