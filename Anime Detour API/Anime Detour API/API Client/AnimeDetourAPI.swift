//
//  AnimeDetourAPIClient.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import Foundation

public typealias APICompletionHandler = (result: AnyObject?, error: NSError?) -> ()

public protocol AnimeDetourAPI {
    /// Formatter for use when parsing API dates.
    /// Do not modify.
    var dateFormatter: NSDateFormatter { get }
    
    // MARK: - Endpoint Methods

    func guestList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask?
    
    func sessionList(completionHandler: APICompletionHandler) -> NSURLSessionDataTask?
}
