//
//  Favorites.swift
//  Listen
//
//  Created by Stefan Trauth on 27/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import Parse

class Favorites {
    
    static let userDefaults = NSUserDefaults.standardUserDefaults()
    static let key = "favorites"
    
    static func fetch() -> [String] {
        if let storedFavorites = userDefaults.objectForKey(key) as? [String] {
            return storedFavorites
        } else {
            // if there is nothing stored yet, create a new empty Array
            return [String]()
        }
    }
    
    static func add(slug slug: String) {
        var favorites = fetch()
        if favorites.count == 0 {
            setupPushNotifications()
        }
        if !favorites.contains(slug) {
            favorites.append(slug)
            userDefaults.setObject(favorites, forKey: key)
            subscribeForPush(slug: slug)
            notifyChange()
        }
    }
    
    static func remove(slug slug: String) {
        var favorites = fetch()
        if let index = favorites.indexOf(slug) {
            favorites.removeAtIndex(index)
            userDefaults.setObject(favorites, forKey: key)
            unsubscribeForPush(slug: slug)
            notifyChange()
        }
    }
    
    static func toggle(slug slug: String) {
        let favorites = fetch()
        if !favorites.contains(slug) {
            add(slug: slug)
        } else {
            remove(slug: slug)
        }
    }
    
    private static func notifyChange() {
        NSNotificationCenter.defaultCenter().postNotificationName("favoritesChanged", object: nil, userInfo: nil)
    }
    
    // MARK: - Parse Push Notification Channels
    
    static func setupPushNotifications() {
        let application = UIApplication.sharedApplication()
        Parse.setApplicationId("8MWfUM4grO3NqKBxXqgxZ61JblY6PtbgrcM0d4f2",
            clientKey: "fymCS10s2tuBBS0GjBKxYoPXcH7pwUaW6BPlyo6I")
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    static func subscribeForPush(slug slug: String) {
        if slug != "" {
            let installation = PFInstallation.currentInstallation()
            installation.addUniqueObject(slug, forKey: "channels")
            installation.saveInBackground()
        }
    }
    
    static func unsubscribeForPush(slug slug: String) {
        if slug != "" {
            let installation = PFInstallation.currentInstallation()
            installation.removeObject(slug, forKey: "channels")
            installation.saveInBackground()
        }
    }
    
}
