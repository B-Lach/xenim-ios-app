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
    
    static func toggle(podcastId: String) {
        let channel = "podcast_\(podcastId)"
        let installation = PFInstallation.current()
        
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
            installation.remove(channel, forKey: "channels")
            notifyFavoriteRemoved(podcastId)
        }
        installation.saveEventually()
    }
    
    static func isFavorite(_ podcastId: String) -> Bool {
        let channel = "podcast_\(podcastId)"
        let installation = PFInstallation.current()
        
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
        let installation = PFInstallation.current()
        
        // fetching will only be required if channels can be modified in the cloud!
        //        do {
        //            try installation.fetch()
        //        } catch {
        //            // TODO
        //        }
        
        if let channels = installation.channels {
            // remove the prefix string 'podcast_' from the channels
            let podcastIds = channels.map { (channel: String) -> String in
                channel.replacingOccurrences(of: "podcast_", with: "")
            }
            return podcastIds
        } else {
            return [String]()
        }
    }
    
    static func fetchFavoritePodcasts(_ onComplete: (podcasts: [Podcast]) -> Void) {
        let podcastIds = fetch()
        var podcasts = [Podcast]()
        
        // just return empty array if there is no favorite podcast at all
        if podcastIds.count == 0 {
            onComplete(podcasts: podcasts)
            return
        }
        
        let blocksDispatchQueue = DispatchQueue(label: "com.domain.blocksArray.sync", attributes: DispatchQueueAttributes.concurrent)
        let serviceGroup = DispatchGroup()
        
        // start one api requirest for each podcast
        for podcastId in podcastIds {
            serviceGroup.enter()
            XenimAPI.fetchPodcast(podcastId: podcastId, onComplete: { (podcast) -> Void in
                blocksDispatchQueue.async {
                    if podcast != nil {
                        // this has to be thread safe
                        podcasts.append(podcast!)
                    }
                    serviceGroup.leave()
                }
            })
        }
        
        // notified as soon as ALL requests are finished
        serviceGroup.notify(queue: DispatchQueue.global()) { 
            onComplete(podcasts: podcasts)
        }
    }
    
    private static func notifyFavoriteAdded(_ podcastId: String) {
        NotificationCenter.default().post(name: Notification.Name(rawValue: "favoriteAdded"), object: nil, userInfo: ["podcastId": podcastId])
    }
    
    private static func notifyFavoriteRemoved(_ podcastId: String) {
        NotificationCenter.default().post(name: Notification.Name(rawValue: "favoriteRemoved"), object: nil, userInfo: ["podcastId": podcastId])
    }
    
}
