//
//  SessionViewModel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import AnimeDetourDataModel

/**
Delegate protocol with which view model state changes, where allowed,
are communicated.
*/
protocol SessionViewModelDelegate {
    func bookmarkImageChanged(_ bookmarkImage: UIImage, accessibilityLabel: String)
}

/**
View model for Sessions. State changes, where handled, are communicated to the `delegate`.
*/
class SessionViewModel {
    let imageURLSession: URLSession?
    let session: Session
    let managedObjectContext: NSManagedObjectContext
    
    var isBookmarked: Bool {
        return self.session.bookmarked
    }
    var bookmarkImage: UIImage {
        if isBookmarked {
            return UIImage(named: "star_filled")!
        } else {
            return UIImage(named: "star")!
        }
    }
    var bookmarkAccessibilityLabel: String {
        if isBookmarked {
            return "Remove Favorite"
        } else {
            return "Add Favorite"
        }
    }
    let startDateFormatter: DateFormatter
    let shortEndDateFormatter: DateFormatter
    let noImageURLSessionError = NSError(domain: "com.animedetour.mobile", code: 1001, userInfo: nil)

    var delegate: SessionViewModelDelegate?

    fileprivate var imageTask: URLSessionDataTask?

    var name: String {
        return session.name
    }
    
    var is18Plus: Bool {
        return session.tags.contains("18+")
    }
    
    var is21Plus: Bool {
        return session.tags.contains("21+")
    }

    var sessionDescription: String? {
        return session.sessionDescription
    }

    var dateAndTime: String {
        let midnightMorningAfterStartDate: Date = {
            let calendar = Calendar.current
            var forwardOneDayComponents = DateComponents()
            forwardOneDayComponents.day = 1
            
            let foundDay = calendar.nextDate(after: self.session.start, matching: forwardOneDayComponents, matchingPolicy: Calendar.MatchingPolicy.nextTime)
            return foundDay!
        }()

        let startDateString = self.startDateFormatter.string(from: session.start)

        // Show long date format for end date if the end time is the next day and 12 hours (43200 seconds)
        // or more after the start date
        let longEndDate = session.end.timeIntervalSince(midnightMorningAfterStartDate) > 0 && session.end.timeIntervalSince(session.start) > 43199
        let endDateFormatter = longEndDate ? self.startDateFormatter : self.shortEndDateFormatter
        let endDateString = endDateFormatter.string(from: session.end)
        return "\(startDateString) - \(endDateString)"
    }

    var location: String {
        return session.room
    }

    var category: String {
        return session.category.name
    }
    
    var categoryWithColor: NSAttributedString {
        let string = NSMutableAttributedString(string: category)
        
        return string
    }
    
    var categoryColor: UIColor? {
        return session.category.color
    }
    
    var panelists: String {
        return session.hosts.joined(separator: ", ")
    }
    
    var hasImage: Bool {
        return imageURL != nil
    }
    
    fileprivate var image: UIImage?

    fileprivate var imageURL: URL? {
        return session.bannerURL
    }

    /**
    Create a view model.

    - parameter imagesURLSession: A URL session to use when downloading images. If `nil`, will not attempt to download images.
    */
    init(session: Session, managedObjectContext: NSManagedObjectContext, imagesURLSession: URLSession?, sessionStartTimeFormatter startDateFormatter: DateFormatter, shortTimeFormatter: DateFormatter) {
        self.session = session
        self.managedObjectContext = managedObjectContext
        self.imageURLSession = imagesURLSession
        self.startDateFormatter = startDateFormatter
        self.shortEndDateFormatter = shortTimeFormatter
    }

    /**
    Get the image for the session. Designed like a poor man's Future.

    - parameter onLoad: A callback to run when the image is available, or an error has occurred. May run immediately, and may not run on the same thread as the caller.
    */
    func image(_ onLoad: @escaping (_ image: UIImage?, _ error: NSError?) -> Void) {
        if self.imageURLSession == nil {
            onLoad(nil, self.noImageURLSessionError)
            return
        }

        if let image = self.image {
            onLoad(image, nil)
            return
        }

        switch self.imageURL {
        case let .some(imageURL) where imageURL.absoluteString.utf8.count > 0:
            let imageTask = self.imageURLSession?.dataTask(with: imageURL, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: NSError?) -> Void in
                guard let data = data else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self?.imageTask = nil
                        return
                    })
                    onLoad(nil, error)
                    return
                }
                
                let image = UIImage(data: data)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self?.imageTask = nil
                    self?.image = image
                    
                    onLoad(image, nil)
                });
            } as! (Data?, URLResponse?, Error?) -> Void)
            self.imageTask = imageTask
            imageTask?.resume()
        default:
            onLoad(nil, nil)
        }
    }

    func toggleBookmarked() throws {
        let wasBookmarked = isBookmarked
        let nowBookmarked = !wasBookmarked

        let session = self.session
        session.bookmarked = nowBookmarked
        
        var succeededTogglingBookmarked = false
        defer {
            if !succeededTogglingBookmarked {
                session.bookmarked = wasBookmarked
            }
        }
        try managedObjectContext.save()
        
        succeededTogglingBookmarked = true

        if let analytics = GAI.sharedInstance().defaultTracker {
            let dict: [NSObject : AnyObject]
            if isBookmarked {
                dict = GAIDictionaryBuilder.createEventDictionary(.Session, action: .Favorite, label: session.name, value: nil)
            } else {
                dict = GAIDictionaryBuilder.createEventDictionary(.Session, action: .Unfavorite, label: session.name, value: nil)
            }
            analytics.send(dict)
        }

        delegate?.bookmarkImageChanged(self.bookmarkImage, accessibilityLabel: self.bookmarkAccessibilityLabel)
    }
}
