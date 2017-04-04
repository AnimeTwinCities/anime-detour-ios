//
//  DateFormatter+DevFest.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let adr_differentDateEndFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mma"
        return formatter
    }()
    
    static let adr_endFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }()
    
    static let adr_startFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mma"
        return formatter
    }()
}
