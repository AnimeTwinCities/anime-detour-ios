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
    case guestList
    case sessionList
    
    var relativeURL: String {
        var url: String
        switch self {
        case .guestList:
            url = "/guest_list/2/"
        case .sessionList:
            url = "/programming_events"
        }
        
        return url
    }
}

public typealias APICompletionHandler = (_ result: Any?, _ error: NSError?) -> ()

open class AnimeDetourAPIClient {
    /// Formatter for use when parsing API dates.
    /// Do not modify.
    open let dateFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ" // 2016-04-22T09:00:00-06:00
        formatter.timeZone = TimeZone(identifier: "America/Chicago")
        return formatter
    }()
    
    internal let urlSession: URLSession
    internal let baseURL: URL = URL(string: "http://animedetour.com")!
    
    required public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Endpoint Methods
    
    open func guestList(_ completionHandler: APICompletionHandler) -> URLSessionDataTask? {
        let url = self.url(fromEndpoint: .guestList)
        let request = URLRequest(url: url)
        let dataTask = self.urlSession.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if let error = error {
                NSLog("Error getting guest list: \(error)")
                completionHandler(nil, error)
                return
            }
            
            guard let data = data else {
                completionHandler(nil, nil)
                return
            }
            
            let json: Any?
            let jsonError: NSError?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
                jsonError = nil
            } catch {
                json = nil
                jsonError = error as NSError
            }
            completionHandler(json, jsonError)
        } as! (Data?, URLResponse?, Error?) -> Void)
        
        dataTask.resume()
        return dataTask
    }
    
    open func sessionList(_ completionHandler: APICompletionHandler) -> URLSessionDataTask? {
        let url = self.url(fromEndpoint: .sessionList)
        let request = URLRequest(url: url)
        let dataTask = self.urlSession.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if let error = error {
                NSLog("Error getting session list: \(error)")
                completionHandler(nil, error)
                return
            }
            
            guard let data = data else {
                completionHandler(nil, nil)
                return
            }
            
            let json: Any?
            let jsonError: NSError?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
                jsonError = nil
            } catch {
                json = nil
                jsonError = error as NSError
            }
            completionHandler(json, jsonError)
        } as! (Data?, URLResponse?, Error?) -> Void)
        
        dataTask.resume()
        return dataTask
    }
    
    // MARK: - Request Building Methods
    
    fileprivate func url(fromEndpoint endpoint: APIEndpoint, queryParameters: [String : String] = [:]) -> URL {
        var relativeURL = endpoint.relativeURL
        relativeURL.append(self.queryString(fromDictionary: queryParameters))
        return URL(string: "\(self.baseURL)\(relativeURL)")!
    }
    
    fileprivate func queryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars = [String]()
        for (k, var v) in parameters {
            v = v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            urlVars += ["\(k)=\(v)"]
        }
        return urlVars.isEmpty ? "" : ("?" + urlVars.joined(separator: "&"))
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
    public func update(jsonObject json: [String : AnyObject], jsonDateFormatter dateFormatter: DateFormatter) {
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
            let date = dateFormatter.date(from: start) {
                self.start = date
        }
        
        if let end = json[SessionJSONKeys.end.rawValue] as? String,
            let date = dateFormatter.date(from: end) {
                self.end = date
        }
        
        if let category = json[SessionJSONKeys.category.rawValue] as? String {
            self.category = Session.Category(name: category)
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
        } else {
            self.sessionDescription = nil
        }
        
        if let bannerURL = json[SessionJSONKeys.bannerURL.rawValue] as? String {
            self.bannerURL = URL(string: bannerURL)
        }
    }
}
