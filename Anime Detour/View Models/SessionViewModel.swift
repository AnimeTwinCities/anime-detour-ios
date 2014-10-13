//
//  SessionViewModel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import ConScheduleKit

class SessionViewModel {
    let session: Session
    let startDateFormatter: NSDateFormatter
    let shortEndDateFormatter: NSDateFormatter
    
    var name: String {
        get {
            return session.name
        }
    }
    
    var description: String {
        get {
            return session.description
        }
    }
    
    var dateAndTime: String {
        get {
            var midnightMorningAfterStartDate: NSDate! = {
                var midnightMorningOfStartDate: NSDate?
                var duration: NSTimeInterval = 0
                let calendar = NSCalendar.currentCalendar()
                calendar.rangeOfUnit(.DayCalendarUnit, startDate: &midnightMorningOfStartDate, interval: &duration, forDate: self.session.start)
                
                let components = NSDateComponents()
                components.day = 1
                
                return calendar.dateByAddingComponents(components, toDate: midnightMorningOfStartDate!, options: NSCalendarOptions.allZeros)
                }()
            
            let startDateString = self.startDateFormatter.stringFromDate(session.start)
            
            // Show long end date format if the end time is the next day and more than
            // 12 hours (43200 seconds) after the start date
            var longEndDate = session.end.timeIntervalSinceDate(midnightMorningAfterStartDate) > 0 && session.end.timeIntervalSinceDate(session.start) > 43199
            let endDateFormatter = longEndDate ? self.startDateFormatter : self.shortEndDateFormatter
            let endDateString = endDateFormatter.stringFromDate(session.end)
            return "\(startDateString) - \(endDateString)"
        }
    }
    
    init(session: Session, sessionStartTimeFormatter startDateFormatter: NSDateFormatter, shortTimeFormatter: NSDateFormatter) {
        self.session = session
        self.startDateFormatter = startDateFormatter
        self.shortEndDateFormatter = shortTimeFormatter
    }
}