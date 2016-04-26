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
    
    func testSnapshotsDE() {
        if deviceLanguage != "de-DE" {
            return
        }
        
        let app = XCUIApplication()
        snapshot("01Events")
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Lage der Nation"].tap()
        snapshot("02PodcastDetail")
        
        app.navigationBars["Lage der Nation"].childrenMatchingType(.Button).matchingIdentifier("Zurück").elementBoundByIndex(0).tap()
        tablesQuery.buttons["Play"].tap()
        sleep(2)
        snapshot("03Player")
        
        app.buttons["expand more"].tap()
        app.toolbars.staticTexts["Testsendung"].pressForDuration(1.9);
        let endPlaybackButton = app.sheets.collectionViews.buttons["Player beenden"]
        endPlaybackButton.tap()

        app.tabBars.buttons["Favoriten"].tap()
        snapshot("04Favorites")
        
        let favoritenNavigationBar = app.navigationBars["Favoriten"]
        favoritenNavigationBar.buttons["brandeis blue 25 plus"].tap()
        snapshot("05AddFavorites")
        
        app.navigationBars["Favoriten finden"].buttons["Fertig"].tap()
        favoritenNavigationBar.buttons["brandeis blue 25 gear"].tap()
        snapshot("06Settings")
    }
    
    func testSnapshotsEN() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        if deviceLanguage != "en-US" {
            return
        }
        
        let app = XCUIApplication()
        snapshot("01Events")
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Lage der Nation"].tap()
        snapshot("02PodcastDetail")
        app.navigationBars["Lage der Nation"].childrenMatchingType(.Button).matchingIdentifier("Back").elementBoundByIndex(0).tap()
        
        
        tablesQuery.buttons["Play"].tap()
        sleep(2)
        snapshot("03Player")
        // close player
        app.buttons["expand more"].tap()
        app.toolbars.staticTexts["Testsendung"].pressForDuration(1.9);
        let endPlaybackButton = app.sheets.collectionViews.buttons["End Playback"]
        endPlaybackButton.tap()
        
        app.tabBars.buttons["Favorites"].tap()
        snapshot("04Favorites")
        
        let favoritesNavigationBar = app.navigationBars["Favorites"]
        favoritesNavigationBar.buttons["brandeis blue 25 plus"].tap()
        snapshot("05AddFavorites")
        app.navigationBars["Add Favorites"].buttons["Done"].tap()
        
        favoritesNavigationBar.buttons["brandeis blue 25 gear"].tap()
        snapshot("06Settings")
    }
    
    //    func setupFavorites() {
    //        let tabBarsQuery = app.tabBars
    //        tabBarsQuery.buttons["Favorites"].tap()
    //        app.navigationBars["Favorites"].buttons["brandeis blue 25 plus"].tap()
    //
    //        var tablesQuery = app.tables
    //        tablesQuery.cells.containingType(.StaticText, identifier:"Freakshow").buttons["scarlet 44 star o"].tap()
    //        tablesQuery.cells.containingType(.StaticText, identifier:"Lage der Nation").buttons["scarlet 44 star o"].tap()
    //        tablesQuery.cells.containingType(.StaticText, identifier:"Not Safe For Work").buttons["scarlet 44 star o"].tap()
    //        tablesQuery.staticTexts["Nerdemissionen"].swipeUp()
    //        tablesQuery.cells.containingType(.StaticText, identifier:"Wrint").buttons["scarlet 44 star o"].tap()
    //        app.navigationBars["Add Favorites"].buttons["Done"].tap()
    //        tabBarsQuery.buttons["Events"].tap()
    //    }
    
}
