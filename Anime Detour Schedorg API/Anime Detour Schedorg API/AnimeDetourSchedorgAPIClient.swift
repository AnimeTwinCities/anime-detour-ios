//
//  AnimeDetourSchedorgAPIClient.swift
//  Anime Detour Schedorg API
//
//  Created by Brendon Justin on 1/9/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

import AnimeDetourDataModel

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

public class AnimeDetourSchedorgAPIClient {
    /// Formatter for use when parsing sched.org API dates.
    /// Do not modify.
    public let dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 2015-08-04 19:00:00
        formatter.timeZone = NSTimeZone(name: "America/Chicago")
        return formatter
    }()
    
    internal let urlSession: NSURLSession
    internal let baseURL: NSURL = NSURL(string: "http://animedetour.com")!
    
    required public init(urlSession: NSURLSession = NSURLSession.sharedSession()) {
        self.urlSession = urlSession
    }
    
    // MARK: - Endpoint Methods
    
    public func guestList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask? {
        let url = self.url(fromEndpoint: .GuestList)
        let request = NSURLRequest(URL: url)
        let dataTask = self.urlSession.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let error = error {
                NSLog("Error getting guest list: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            guard let data = data else {
                completionHandler(result: nil, error: nil)
                return
            }
            
            let json: AnyObject?
            let jsonError: NSError?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                jsonError = nil
            } catch {
                json = nil
                jsonError = error as NSError
            }
            completionHandler(result: json, error: jsonError)
        })
        
        dataTask.resume()
        return dataTask
    }
    
    public func sessionList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask? {
        let url = self.url(fromEndpoint: .SessionList)
        let request = NSURLRequest(URL: url)
        let dataTask = self.urlSession.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let error = error {
                NSLog("Error getting session list: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            guard let data = data else {
                completionHandler(result: nil, error: nil)
                return
            }
            
            let json: AnyObject?
            let jsonError: NSError?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                jsonError = nil
            } catch {
                json = nil
                jsonError = error as NSError
            }
            completionHandler(result: json, error: jsonError)
        })
        
        dataTask.resume()
        return dataTask
    }
    
    // MARK: - Request Building Methods
    
    private func url(fromEndpoint endpoint: APIEndpoint, queryParameters: [String : String] = [:]) -> NSURL {
        var relativeURL = endpoint.relativeURL
        relativeURL.appendContentsOf(self.queryString(fromDictionary: queryParameters))
        return NSURL(string: "\(self.baseURL)\(relativeURL)")!
    }
    
    private func queryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars = [String]()
        for (k, var v) in parameters {
            v = v.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            urlVars += ["\(k)=\(v)"]
        }
        return urlVars.isEmpty ? "" : ("?" + urlVars.joinWithSeparator("&"))
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

public struct SessionJSONKeys {
    public static let key = "event_key"
    public static let active = "active"
    public static let name = "name"
    public static let start = "event_start"
    public static let end = "event_end"
    public static let type = "event_type"
    public static let sessionDescription = "description"
    public static let mediaURL = "media_url"
    public static let seats = "seats"
    public static let goers = "goers"
    public static let inviteOnly = "invite_only"
    public static let venue = "venue"
    public static let address = "address"
    public static let sessionID = "id"
    public static let venueID = "venue_id"
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
        
        if let start: String = json["event_start"],
            let date = dateFormatter.dateFromString(start) {
                self.start = date
        }
        
        if let end: String = json["event_end"],
            let date = dateFormatter.dateFromString(end) {
                self.end = date
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
        
        if let seatsString = json["seats"],
            let seats = Int(seatsString).map({ UInt32($0) }) {
                self.seats = seats
        }
        
        if let goersString = json["goers"],
            let goers = Int(goersString).map({ UInt32($0) }) {
                self.goers = goers
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
        
        if let sessionID: String = json[SessionJSONKeys.sessionID] {
            self.sessionID = sessionID
        }
        
        if let venueID: String = json["venue_id"] {
            self.venueID = venueID
        }
    }
}
