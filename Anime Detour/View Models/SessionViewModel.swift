//
//  SessionViewModel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit

import AnimeDetourAPI

/**
Delegate protocol with which view model state changes, where allowed,
are communicated.
*/
protocol SessionViewModelDelegate {
    func bookmarkImageChanged(bookmarkImage: UIImage, accessibilityLabel: String)
}

/**
View model for Sessions. State changes, where handled, are communicated to the `delegate`.
*/
class SessionViewModel {
    let imageURLSession: NSURLSession?
    let session: Session
    private var bookmarked: Bool {
        return self.session.bookmarked
    }
    var bookmarkImage: UIImage {
        if self.bookmarked {
            return UIImage(named: "star_filled")!
        } else {
            return UIImage(named: "star")!
        }
    }
    var bookmarkAccessibilityLabel: String {
        if self.bookmarked {
            return "Remove Bookmark"
        } else {
            return "Bookmark"
        }
    }
    let startDateFormatter: NSDateFormatter
    let shortEndDateFormatter: NSDateFormatter
    let noImageURLSessionError = NSError(domain: "com.animedetour.mobile", code: 1001, userInfo: nil)

    var delegate: SessionViewModelDelegate?

    private var imageTask: NSURLSessionDataTask?

    var name: String {
        return session.name
    }

    var sessionDescription: String {
        return session.sessionDescription
    }

    var dateAndTime: String {
        let midnightMorningAfterStartDate: NSDate = {
            var midnightMorningOfStartDate: NSDate?
            var duration: NSTimeInterval = 0
            let calendar = NSCalendar.currentCalendar()
            calendar.rangeOfUnit(.Day, startDate: &midnightMorningOfStartDate, interval: &duration, forDate: self.session.start)

            let components = NSDateComponents()
            components.day = 1

            return calendar.dateByAddingComponents(components, toDate: midnightMorningOfStartDate!, options: NSCalendarOptions())!
            }()

        let startDateString = self.startDateFormatter.stringFromDate(session.start)

        // Show long date format for end date if the end time is the next day and 12 hours (43200 seconds)
        // or more after the start date
        let longEndDate = session.end.timeIntervalSinceDate(midnightMorningAfterStartDate) > 0 && session.end.timeIntervalSinceDate(session.start) > 43199
        let endDateFormatter = longEndDate ? self.startDateFormatter : self.shortEndDateFormatter
        let endDateString = endDateFormatter.stringFromDate(session.end)
        return "\(startDateString) - \(endDateString)"
    }

    var location: String? {
        return session.venue
    }

    /**
    The primary color for our session, i.e. the color corresponding to our session's
    primary type.
    */
    var primaryColor: UIColor {
        // Default to gray #333333
        return self.sessionType?.color ?? UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
    }

    /// The Session's primary type.
    var type: String {
        return session.type
    }

    /// A comma-separated string of all of the Session's types.
    var types: String {
        return session.types.joinWithSeparator(", ")
    }

    /**
    The primary type of our session.
    */
    private var sessionType: SessionType? {
        return SessionType.from(self.type)
    }

    private var image: UIImage?

    private var imageURL: NSURL? {
        return NSURL(string: session.mediaURL)
    }

    /**
    Create a view model.

    - parameter imagesURLSession: A URL session to use when downloading images. If `nil`, will not attempt to download images.
    */
    init(session: Session, imagesURLSession: NSURLSession?, sessionStartTimeFormatter startDateFormatter: NSDateFormatter, shortTimeFormatter: NSDateFormatter) {
        self.session = session
        self.imageURLSession = imagesURLSession
        self.startDateFormatter = startDateFormatter
        self.shortEndDateFormatter = shortTimeFormatter
    }

    /**
    Get the image for the session. Designed like a poor man's Future.

    - parameter onLoad: A callback to run when the image is available, or an error has occurred. May run immediately, and may not run on the same thread as the caller.
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
        case let .Some(imageURL) where imageURL.absoluteString.utf8.count > 0:
            let imageTask = self.imageURLSession?.dataTaskWithURL(imageURL, completionHandler: { [weak self] (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                guard let data = data else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self?.imageTask = nil
                        return
                    })
                    onLoad(image: nil, error: error)
                    return
                }
                
                let image = UIImage(data: data)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self?.imageTask = nil
                    self?.image = image
                    
                    onLoad(image: image, error: nil)
                });
            })
            self.imageTask = imageTask
            imageTask?.resume()
        default:
            onLoad(image: nil, error: nil)
        }
    }

    func toggleBookmarked() {
        let wasBookmarked = self.bookmarked
        let isBookmarked = !wasBookmarked

        let session = self.session
        session.bookmarked = isBookmarked
        do {
            try session.managedObjectContext?.save()
        } catch {
            NSLog("Couldn't save after toggling session bookmarked status: \((error as NSError).localizedDescription)")
        }

        if let analytics = GAI.sharedInstance().defaultTracker {
            let dict: NSDictionary
            if isBookmarked {
                dict = GAIDictionaryBuilder.createEventWithCategory(AnalyticsConstants.Category.Session, action: AnalyticsConstants.Actions.Favorite, label: session.name, value: nil).build()
            } else {
                dict = GAIDictionaryBuilder.createEventWithCategory(AnalyticsConstants.Category.Session, action: AnalyticsConstants.Actions.Unfavorite, label: session.name, value: nil).build()
            }
            analytics.send(dict as! [NSObject : AnyObject])
        }

        self.delegate?.bookmarkImageChanged(self.bookmarkImage, accessibilityLabel: self.bookmarkAccessibilityLabel)
    }
}