//
//  XenimUITests.swift
//  XenimUITests
//
//  Created by Stefan Trauth on 19/04/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import XCTest

class XenimUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        
        let app = XCUIApplication()
        
        snapshot("01Events")
        
        app.tables.staticTexts["Lage der Nation"].tap()
        snapshot("02PodcastDetail")
        app.navigationBars["Lage der Nation"].childrenMatchingType(.Button).matchingIdentifier("Back").elementBoundByIndex(0).tap()
        
        // TODOplayer
        
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Favorites"].tap()
        snapshot("03Favorites")
        
        let favoritesNavigationBar = app.navigationBars["Favorites"]
        favoritesNavigationBar.buttons["brandeis blue 25 plus"].tap()
        snapshot("04AddFavorites")
        app.navigationBars["Add Favorites"].buttons["Done"].tap()
        
        favoritesNavigationBar.buttons["brandeis blue 25 gear"].tap()
        snapshot("06Settings")
        app.navigationBars["Settings"].buttons["Done"].tap()
        tabBarsQuery.buttons["Events"].tap()
        
    }
    
}
