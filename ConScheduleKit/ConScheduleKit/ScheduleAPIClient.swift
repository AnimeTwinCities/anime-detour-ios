//
//  ScheduleAPIClient.swift
//  ConScheduleKit
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

enum APIEndpoint {
    case SessionList
    case SessionCount
    
    var relativeURL: String {
        var url: String
        switch self {
        case .SessionCount:
            url = "/session/count"
        case .SessionList:
            url = "/session/list"
        }
        
        return url
    }
}

public typealias APICompletionHandler = (result: AnyObject?, error: NSError?) -> ()

public class ScheduleAPIClient {
    let apiKey: String
    let subdomain: String
    
    /// Formatter for use when parsing sched.org API dates.
    /// Do not modify.
    public let dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 2015-08-04 19:00:00
        return formatter
    }()
    
    internal lazy var urlSession: NSURLSession = NSURLSession.sharedSession()
    private var baseURL: NSURL {
        return NSURL(string: "http://\(self.subdomain).sched.org/api")!
    }
    
    required public init(subdomain: String, apiKey: String, conLocationTimeZone timeZone: NSTimeZone) {
        self.apiKey = apiKey
        self.subdomain = subdomain
        
        self.dateFormatter.timeZone = timeZone
    }
    
    convenience public init(subdomain: String, apiKey: String, conLocationTimeZone timeZone: NSTimeZone, urlSession: NSURLSession) {
        assert(countElements(subdomain) > 0, "Subdomain must be non-zero length.")
        self.init(subdomain: subdomain, apiKey: apiKey, conLocationTimeZone: timeZone)
        self.urlSession = urlSession
    }
    
    // MARK: - Endpoint Methods
    
    public func sessionList(since: NSDate? = nil, deletedSessions: Bool, completionHandler: APICompletionHandler) -> NSURLSessionDataTask {
        // calls a URL like:
        // http://your_conference.sched.org/api/session/list?api_key=secret&since=1282755813&format=json&status=del&custom_data=Y
        var parameters: [String:String] = [:]
        if let since = since {
            parameters["since"] = "\(since.timeIntervalSince1970)"
        }
        if deletedSessions {
            parameters["status"] = "del"
        }
        
        let url = self.url(fromEndpoint:.SessionList, queryParameters: parameters)
        let request = NSURLRequest(URL: url)
        let dataTask = self.urlSession.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let error = error {
                NSLog("Error getting session list: \(error)")
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
        queryParameters["api_key"] = self.apiKey
        queryParameters["format"] = "json"
        
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
