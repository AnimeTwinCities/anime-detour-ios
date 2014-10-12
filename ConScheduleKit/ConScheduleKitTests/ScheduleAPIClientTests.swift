//
//  ScheduleAPIClientTests.swift
//  ConScheduleKit
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation

import XCTest

class ScheduleAPIKitTests: XCTestCase {
    var apiClient: ScheduleAPIClient!
    
    override func setUp() {
        super.setUp()
        
        self.apiClient = ScheduleAPIClient(subdomain: "ssetest2015", apiKey: "21856730f40671b94b132ca11d35cd5d")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSessionList() {
        let expectation = self.expectationWithDescription("API Call Happens")
        self.apiClient.sessionList(since: nil, deletedSessions: false)
        
        self.waitForExpectationsWithTimeout(60, handler: { (error: NSError!) -> Void in
            
        })
        XCTAssertTrue(0 == 0, "Yep")
    }
    
}
