//
//  AnimeDetourAPIClient.swift
//  Anime Detour API
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
            url = "/events"
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

public enum SessionJSONKeys: String {
    case bannerURL = "banner"
    case category
    case sessionDescription = "description"
    case end
    case hosts
    case name
    case room
    case sessionID = "id"
    case start
    case tags
}

public extension Session {
    /// Update the session's stored properties with information from an API response.
    /// Does not save the object afterward.
    public func update(jsonObject json: [String : AnyObject], jsonDateFormatter dateFormatter: NSDateFormatter) {
        /**
        JSON like:
        {
        "id": "test-01",
        "name": "Opening Ceremonies",
        "start": "2016-04-22T16:00:00-06:00",
        "end": "2016-04-22T17:00:00-06:00",
        "category": "Panel",
        "tags": [
        "official"
        ],
        "room": "Main Stage",
        "hosts": [],
        "description": "Curabitur aliquet <strong>quam id</strong> dui <a href='http://example.com'>posuere blandit</a>. Mauris blandit aliquet elit, eget tincidunt nibh pulvinar a. Vestibulum ac diam sit amet quam vehicula elementum sed sit amet dui. Vestibulum ac diam sit amet quam vehicula elementum sed sit amet dui. Curabitur non nulla sit amet nisl tempus convallis quis ac lectus. Curabitur aliquet quam id dui posuere blandit. Donec sollicitudin molestie malesuada. Donec sollicitudin molestie malesuada. Curabitur non nulla sit amet nisl tempus convallis quis ac lectus. Curabitur aliquet quam id dui posuere blandit.",
        "banner": "http://photos.animedetour.com/Anime-Detour-2014/i-hBjX6XW/0/X3/DSC08740-X3.jpg"
        },
        */
        
        if let sessionID = json[SessionJSONKeys.sessionID.rawValue] as? String {
            self.sessionID = sessionID
        }
        
        if let name = json[SessionJSONKeys.name.rawValue] as? String {
            self.name = name
        }
        
        if let start = json[SessionJSONKeys.start.rawValue] as? String,
            let date = dateFormatter.dateFromString(start) {
                self.start = date
        }
        
        if let end = json[SessionJSONKeys.end.rawValue] as? String,
            let date = dateFormatter.dateFromString(end) {
                self.end = date
        }
        
        if let category = json[SessionJSONKeys.category.rawValue] as? String {
            self.category = category
        }
        
        if let tags = json[SessionJSONKeys.tags.rawValue] as? [String] {
            self.tags = tags
        }
        
        if let room = json[SessionJSONKeys.room.rawValue] as? String {
            self.room = room
        }
        
        if let hosts = json[SessionJSONKeys.hosts.rawValue] as? [String] {
            self.hosts = hosts
        }
        
        if let description = json[SessionJSONKeys.sessionDescription.rawValue] as? String {
            self.sessionDescription = description
        }
        
        if let bannerURL = json[SessionJSONKeys.bannerURL.rawValue] as? String {
            self.bannerURL = NSURL(string: bannerURL)
        }
    }
}
