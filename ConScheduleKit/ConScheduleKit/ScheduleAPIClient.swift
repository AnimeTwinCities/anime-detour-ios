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

public class ScheduleAPIClient {
    let apiKey: String
    let subdomain: String
    let urlSession: NSURLSession
    private var baseURL: NSURL {
        return NSURL(string: "http://\(self.subdomain).sched.org/api")!
    }
    
    required public init(subdomain: String, apiKey: String, urlSession: NSURLSession) {
        assert(countElements(subdomain) > 0, "Subdomain must be non-zero length.")
        self.apiKey = apiKey
        self.subdomain = subdomain
        self.urlSession = urlSession
    }
    
    convenience public init(subdomain: String, apiKey: String, urlSessionConfiguration: NSURLSessionConfiguration) {
        let urlSession = NSURLSession(configuration: urlSessionConfiguration)
        self.init(subdomain: subdomain, apiKey: apiKey, urlSession: urlSession)
    }
    
    convenience public init(subdomain: String, apiKey: String) {
        let urlSession = NSURLSession.sharedSession()
        self.init(subdomain: subdomain, apiKey: apiKey, urlSession: urlSession)
    }
    
    // MARK: - Endpoint Methods
    
    public func sessionList(since: NSDate? = nil, deletedSessions: Bool) -> NSURLSessionDataTask {
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
            
            let body: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
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