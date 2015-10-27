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
            return [String]()
        }
    }
    
    static func add(slug slug: String) {
        var favorites = fetch()
        if !favorites.contains(slug) {
            favorites.append(slug)
            userDefaults.setObject(favorites, forKey: key)
        }
    }
    
    static func remove(slug slug: String) {
        var favorites = fetch()
        if let index = favorites.indexOf(slug) {
            favorites.removeAtIndex(index)
            userDefaults.setObject(favorites, forKey: key)
        }
    }
    
}
