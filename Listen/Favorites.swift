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
    
    static func add(podcastId podcastId: String) {
        var favorites = fetch()
        if !favorites.contains(podcastId) {
            favorites.append(podcastId)
            userDefaults.setObject(favorites, forKey: key)
            PushNotificationManager.subscribeToChannel(podcastId)
            notifyChange()
        }
    }
    
    static func remove(podcastId podcastId: String) {
        var favorites = fetch()
        if let index = favorites.indexOf(podcastId) {
            favorites.removeAtIndex(index)
            userDefaults.setObject(favorites, forKey: key)
            PushNotificationManager.unsubscribeFromChannel(podcastId)
            notifyChange()
        }
    }
    
    static func toggle(podcastId podcastId: String) {
        let favorites = fetch()
        if !favorites.contains(podcastId) {
            add(podcastId: podcastId)
        } else {
            remove(podcastId: podcastId)
        }
    }
    
    private static func notifyChange() {
        NSNotificationCenter.defaultCenter().postNotificationName("favoritesChanged", object: nil, userInfo: nil)
    }
    
}
