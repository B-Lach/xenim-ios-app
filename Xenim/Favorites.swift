//
//  Favorites.swift
//  Xenim
//
//  Created by Stefan Trauth on 27/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import Parse

class Favorites {
    
    static func toggle(podcastId podcastId: String) {
        let channel = "podcast_\(podcastId)"
        let installation = PFInstallation.currentInstallation()
        
         //fetching will only be required if channels can be modified in the cloud!
//                do {
//                    try installation.fetch()
//                } catch {
//                    // TODO
//                }
        if installation.channels == nil {
            installation.channels = [String]()
        }
        if !installation.channels!.contains(channel) {
            installation.addUniqueObject(channel, forKey: "channels")
            notifyFavoriteAdded(podcastId)
        } else {
            installation.removeObject(channel, forKey: "channels")
            notifyFavoriteRemoved(podcastId)
        }
        installation.saveEventually()
    }
    
    static func isFavorite(podcastId: String) -> Bool {
        let channel = "podcast_\(podcastId)"
        let installation = PFInstallation.currentInstallation()
        
        // fetching will only be required if channels can be modified in the cloud!
        //        do {
        //            try installation.fetch()
        //        } catch {
        //            // TODO
        //        }
        
        if let channels = installation.channels {
            return channels.contains(channel)
        } else {
            return false
        }
    }
    
    static func fetch() -> [String] {
        let installation = PFInstallation.currentInstallation()
        
        // fetching will only be required if channels can be modified in the cloud!
        //        do {
        //            try installation.fetch()
        //        } catch {
        //            // TODO
        //        }
        
        if let channels = installation.channels {
            // remove the prefix string 'podcast_' from the channels
            let podcastIds = channels.map { (channel: String) -> String in
                channel.stringByReplacingOccurrencesOfString("podcast_", withString: "")
            }
            return podcastIds
        } else {
            return [String]()
        }
    }
    
    static func fetchFavoritePodcasts(onComplete: (podcasts: [Podcast]) -> Void) {
        let podcastIds = fetch()
        var podcasts = [Podcast]()
        
        // just return empty array if there is no favorite podcast at all
        if podcastIds.count == 0 {
            onComplete(podcasts: podcasts)
        }
        
        let serviceGroup = dispatch_group_create()
        
        // start one api requirest for each podcast
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
        
        // notified as soon as ALL requests are finished
        dispatch_group_notify(serviceGroup, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            onComplete(podcasts: podcasts)
        }
        
        // TODO onComplete will never be called if one of these request fails or times out
    }
    
    private static func notifyFavoriteAdded(podcastId: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("favoriteAdded", object: nil, userInfo: ["podcastId": podcastId])
    }
    
    private static func notifyFavoriteRemoved(podcastId: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("favoriteRemoved", object: nil, userInfo: ["podcastId": podcastId])
    }
    
}
