//
//  AnimeDetourAPIClient.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import Foundation

enum APIEndpoint {
    case GuestList
    case SessionList
    
    var relativeURL: String {
        var url: String
        switch self {
        case .GuestList:
            url = "/guest_list/2/"
        case .SessionList:
            url = "/sched_events"
        }
        
        return url
    }
}

public typealias APICompletionHandler = (result: AnyObject?, error: NSError?) -> ()

public class AnimeDetourAPIClient {
    /// Formatter for use when parsing sched.org API dates.
    /// Do not modify.
    public let dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 2015-08-04 19:00:00
        return formatter
    }()
    
    internal lazy var urlSession: NSURLSession = NSURLSession.sharedSession()
    private var baseURL: NSURL {
        return NSURL(string: "http://animedetour.com")!
    }
    
    required public init() {
        self.dateFormatter.timeZone = NSTimeZone(name: "America/Chicago")
    }
    
    convenience public init(urlSession: NSURLSession) {
        self.init()
        self.urlSession = urlSession
    }
    
    // MARK: - Endpoint Methods

    public func guestList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask {
        let url = self.url(fromEndpoint: .GuestList)
        let request = NSURLRequest(URL: url)
        let dataTask = self.urlSession.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let error = error {
                NSLog("Error getting guest list: \(error)")
                completionHandler(result: nil, error: error)
                return
            }

            var jsonError: NSError?
            let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
            completionHandler(result: json, error: jsonError)
        })

        dataTask.resume()
        return dataTask
    }
    
    public func sessionList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask {
        let url = self.url(fromEndpoint: .SessionList)
        let request = NSURLRequest(URL: url)
        let dataTask = self.urlSession.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let error = error {
                NSLog("Error getting session list: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            var jsonError: NSError?
            let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
            completionHandler(result: json, error: jsonError)
        })
        
        dataTask.resume()
        return dataTask
    }
    
    // MARK: - Request Building Methods
    
    private func url(fromEndpoint endpoint: APIEndpoint, var queryParameters: [String : String] = [:]) -> NSURL {
        var relativeURL = endpoint.relativeURL
        relativeURL.extend(self.queryString(fromDictionary: queryParameters))
        return NSURL(string: "\(self.baseURL)\(relativeURL)")!
    }
    
    private func queryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars = [String]()
        for (k, var v) in parameters {
            v = v.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            urlVars += ["\(k)=\(v)"]
        }
        return urlVars.isEmpty ? "" : ("?" + "&".join(urlVars))
    }
}

public extension Guest {
    /// Update the Guest's stored properties with information from an API response.
    /// Does not save the object afterward.
    public func update(categoryName category: String, jsonObject json: [String : String]) {
        self.category = category

        if let id = json["id"] {
            self.guestID = id
        }

        if let firstName = json["FirstName"] {
            self.firstName = firstName
        }

        if let lastName = json["LastName"] {
            self.lastName = lastName
        }

        if let bio = json["Bio"] {
            self.bio = bio
        }

        if let photoPath = json["PhotoPath"] {
            self.photoPath = photoPath
        }

        if let hiResPhotoPath = json["HiResPhotoPath"] {
            self.hiResPhotoPath = hiResPhotoPath
        }
    }
}

public extension Session {
    /// Update the session's stored properties with information from an API response.
    /// Does not save the object afterward.
    public func update(jsonObject json: [String : String], jsonDateFormatter dateFormatter: NSDateFormatter) {
        if let key: String = json["event_key"] {
            self.key = key
        }
        
        if let active: Bool = json["active"].map({ (active: String) -> Bool in return active == "Y" }) {
            self.active = active
        }
        
        if let name: String = json["name"] {
            self.name = name
        }
        
        if let start: String = json["event_start"] {
            if let date = dateFormatter.dateFromString(start) {
                self.start = date
            }
        }
        
        if let end: String = json["event_end"] {
            if let date = dateFormatter.dateFromString(end) {
                self.end = date
            }
        }
        
        if let type: String = json["event_type"] {
            self.type = type
        }
        
        if let description: String = json["description"] {
            self.sessionDescription = description
        }
        
        if let mediaURL: String = json["media_url"] {
            self.mediaURL = mediaURL
        }
        
        if let seatsString = json["seats"] {
            if let seats = seatsString.toInt().map({ UInt32($0) }) {
                self.seats = seats
            }
        }
        
        if let goersString = json["goers"] {
            if let goers = goersString.toInt().map({ UInt32($0) }) {
                self.goers = goers
            }
        }
        
        if let inviteOnly: Bool = json["inviteOnly"].map({ (inviteOnly: String) -> Bool in return inviteOnly == "Y" }) {
            self.inviteOnly = inviteOnly
        }
        
        if let venue: String = json["venue"] {
            self.venue = venue
        }
        
        if let address: String = json["address"] {
            self.address = address
        }
        
        if let sessionID: String = json["id"] {
            self.sessionID = sessionID
        }
        
        if let venueID: String = json["venue_id"] {
            self.venueID = venueID
        }
    }
}
