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
        
        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Phone:
            app.navigationBars["Lage der Nation"].childrenMatchingType(.Button).matchingIdentifier("Zurück").elementBoundByIndex(0).tap()
        case .Pad:
            break
        default: break
        }
        tablesQuery.buttons["play button"].tap()
        sleep(2)
        snapshot("03Player")
        
        // close player
        app.navigationBars["Funkenstrahlen"].buttons["Stopp"].tap()
        

        app.tabBars.buttons["Favoriten"].tap()
        snapshot("04Favorites")
        
        let favoritenNavigationBar = app.navigationBars["Favoriten"]
        favoritenNavigationBar.buttons["Hinzufügen"].tap()
        snapshot("05AddFavorites")
    }
    
    func testSnapshotsEN() {
        if deviceLanguage != "en-US" {
            return
        }
        
        let app = XCUIApplication()
        snapshot("01Events")
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Lage der Nation"].tap()
        snapshot("02PodcastDetail")
        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Phone:
            app.navigationBars["Lage der Nation"].childrenMatchingType(.Button).matchingIdentifier("Back").elementBoundByIndex(0).tap()
        case .Pad:
            break
        default: break
        }
        
        
        app.tables.buttons["play button"].tap()
        sleep(2)
        snapshot("03Player")
        // close player
        app.navigationBars["Funkenstrahlen"].buttons["Stopp"].tap()
        
        app.tabBars.buttons["Favorites"].tap()
        snapshot("04Favorites")
        
        let favoritesNavigationBar = app.navigationBars["Favorites"]
        favoritesNavigationBar.buttons["Add"].tap()
        snapshot("05AddFavorites")
    }
    
}
