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
    let imageURLSession: NSURLSession?
    let session: Session
    let startDateFormatter: NSDateFormatter
    let shortEndDateFormatter: NSDateFormatter
    let noImageURLSessionError = NSError(domain: "com.nagasoftworks.anime-detour", code: 1001, userInfo: nil)
    
    private var imageTask: NSURLSessionDataTask?
    
    var name: String {
        get {
            return session.name
        }
    }
    
    var sessionDescription: String {
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
    
    private var imageURL: NSURL? {
        get {
            return NSURL(string: session.mediaURL)
        }
    }
    
    private var image: UIImage?
    
    /**
    Get the image for the session. Designed like a poor man's Future.
    
    :param: onLoad A callback to run when the image is available, or an error has occurred. May run immediately, and may not run on the same thread as the caller.
    */
    func image(onLoad: (image: UIImage?, error: NSError?) -> Void) {
        if self.imageURLSession == nil {
            onLoad(image: nil, error: self.noImageURLSessionError)
            return
        }
        
        if let image = self.image {
            onLoad(image: image, error: nil)
            return
        }
        
        switch self.imageURL {
        case let .Some(imageURL) where (imageURL.absoluteString.map(countElements) ?? 0) > 0:
            let imageTask = self.imageURLSession?.dataTaskWithURL(imageURL, completionHandler: { [weak self] (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                if let data = data {
                    let image = UIImage(data: data)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self?.imageTask = nil
                        self?.image = image
                        
                        onLoad(image: image, error: nil)
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self?.imageTask = nil
                        return
                    })
                    onLoad(image: nil, error: error)
                }
            })
            self.imageTask = imageTask
            imageTask?.resume()
        default:
            onLoad(image: nil, error: nil)
        }
    }
    
    /**
    Create a view model.
    
    :param: imagesURLSession A URL session to use when downloading images. If `nil`, will not attempt to download images.
    */
    init(session: Session, imagesURLSession: NSURLSession?, sessionStartTimeFormatter startDateFormatter: NSDateFormatter, shortTimeFormatter: NSDateFormatter) {
        self.session = session
        self.imageURLSession = imagesURLSession
        self.startDateFormatter = startDateFormatter
        self.shortEndDateFormatter = shortTimeFormatter
    }
}