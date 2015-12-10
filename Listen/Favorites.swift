//
//  Favorites.swift
//  Listen
//
//  Created by Stefan Trauth on 27/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation

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
            PushNotificationManager.setupPushNotifications()
        }
        if !favorites.contains(slug) {
            favorites.append(slug)
            userDefaults.setObject(favorites, forKey: key)
            PushNotificationManager.subscribeToChannel(slug)
            notifyChange()
        }
    }
    
    static func remove(slug slug: String) {
        var favorites = fetch()
        if let index = favorites.indexOf(slug) {
            favorites.removeAtIndex(index)
            userDefaults.setObject(favorites, forKey: key)
            PushNotificationManager.unsubscribeFromChannel(slug)
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
    
}
