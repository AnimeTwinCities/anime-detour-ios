//
//  Anime_Detour_Screenshots.swift
//  Anime Detour Screenshots
//
//  Created by Brendon Justin on 3/30/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import XCTest

class AnimeDetourScreenshots: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testTakeScreenshots() {
        let app = XCUIApplication()
        
        let collectionViewsQuery = app.collectionViews
        let sessionTitleToFind = "Anime in 2040"
        while !collectionViewsQuery.staticTexts[sessionTitleToFind].exists {
            let allBoundByIndex = collectionViewsQuery.cells.allElementsBoundByIndex
            // The middle item is very likely to be in the middle of the view,
            // making it a safe choice to scroll as far as necessary.
            allBoundByIndex[allBoundByIndex.count / 2].swipeUp()
        }
        
        snapshot("01-Sessions", waitForLoadingIndicator: false)
        
        collectionViewsQuery.staticTexts[sessionTitleToFind].tap()
        
        snapshot("02-Single_Session", waitForLoadingIndicator: false)
        
//        app.tabBars.buttons["Schedule"].tap()
//        
//        app.navigationBars["Sessions"].buttons["Search"].tap()
//        app.searchFields["Search Sessions"].tap()
//        app.typeText("Pokemon")
//        
//        app.keyboards.buttons["Search"].tap()
//        
//        snapshot("03-Search", waitForLoadingIndicator: false)
//        
//        let done = app.navigationBars["Search"].buttons["Done"]
//        // For some reason, the `Done` button in the nav bar isn't `hittable`.
//        // Get its coordinate on screen and tap there instead of using it directly.
//        if done.isHittable {
//            done.tap()
//        } else {
//            let coordinate: XCUICoordinate = done.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
//            coordinate.tap()
//        }

        let tabBarsQuery = app.tabBars
        let guestsButton = tabBarsQuery.buttons["Guests"]
        guestsButton.tap()
        
        snapshot("04-Guests", waitForLoadingIndicator: false)
        
        app.collectionViews.cells.otherElements.containing(.staticText, identifier: "Greg Ayres").element.tap()
        
        snapshot("05-Single_Guest", waitForLoadingIndicator: false)
        
        guestsButton.tap()
        tabBarsQuery.buttons["Map"].tap()
        
        snapshot("06-Maps", waitForLoadingIndicator: false)
        
        tabBarsQuery.buttons["Info"].tap()
        
        snapshot("07-Info", waitForLoadingIndicator: false)
    }
}
