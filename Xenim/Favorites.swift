//
//  Favorites.swift
//  Xenim
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
            PushNotificationManager.subscribeToPodcastChannel(podcastId)
            notifyFavoriteAdded(podcastId)
        }
    }
    
    static func remove(podcastId podcastId: String) {
        var favorites = fetch()
        if let index = favorites.indexOf(podcastId) {
            favorites.removeAtIndex(index)
            userDefaults.setObject(favorites, forKey: key)
            PushNotificationManager.unsubscribeFromPodcastChannel(podcastId)
            notifyFavoriteRemoved(podcastId)
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
    
    static func fetchFavoritePodcasts(onComplete: (podcasts: [Podcast]) -> Void) {
        let podcastIds = fetch()
        var podcasts = [Podcast]()
        let serviceGroup = dispatch_group_create()
        
        for podcastId in podcastIds {
            dispatch_group_enter(serviceGroup)
            XenimAPI.fetchPodcastById(podcastId, onComplete: { (podcast) -> Void in
                if podcast != nil {
                    // this has to be thread safe
                    objc_sync_enter(podcasts)
                    podcasts.append(podcast!)
                    objc_sync_exit(podcasts)
                }
                dispatch_group_leave(serviceGroup)
            })
        }
        
        dispatch_group_notify(serviceGroup, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            onComplete(podcasts: podcasts)
        }
    }
    
    private static func notifyFavoriteAdded(podcastId: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("favoriteAdded", object: nil, userInfo: ["podcastId": podcastId])
        notifyChange()
    }
    
    private static func notifyFavoriteRemoved(podcastId: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("favoriteRemoved", object: nil, userInfo: ["podcastId": podcastId])
        notifyChange()
    }
    
    private static func notifyChange() {
        NSNotificationCenter.defaultCenter().postNotificationName("favoritesChanged", object: nil, userInfo: nil)
    }
    
}
