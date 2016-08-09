//
//  Favorites.swift
//  Xenim
//
//  Created by Stefan Trauth on 27/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import Parse
import XenimAPI

class Favorites {
    
    static let favoriteAddedNotification = Notification.Name("favoriteAdded")
    static let favoriteRemovedNotification = Notification.Name("favoriteRemoved")
    
    static func toggle(podcastId: String) {
        let channel = "podcast_\(podcastId)"
        if let installation = PFInstallation.current() {
            
            // initialize channels if it is nil
            if installation.channels == nil {
                installation.channels = [String]()
            }
            if let channels = installation.channels {
                if channels.contains(channel) {
                    installation.remove(channel, forKey: "channels")
                    notifyFavoriteRemoved(podcastId)
                } else {
                    installation.addUniqueObject(channel, forKey: "channels")
                    notifyFavoriteAdded(podcastId)
                }
            }
            installation.saveEventually()
            // channels can not be nil
        }
    }
    
    static func isFavorite(_ podcastId: String) -> Bool {
        let channel = "podcast_\(podcastId)"
        if let installation = PFInstallation.current(), let channels = installation.channels {
            return channels.contains(channel)
        }
        return false
    }
    
    static func fetch() -> [String] {
        if let installation = PFInstallation.current(), let channels = installation.channels {
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
        
        let blocksDispatchQueue = DispatchQueue(label: "com.domain.blocksArray.sync", attributes: DispatchQueue.Attributes.concurrent)
        let serviceGroup = DispatchGroup()
        
        // start one api request for each podcast
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
        NotificationCenter.default.post(name: favoriteAddedNotification, object: nil, userInfo: ["podcastId": podcastId])
    }
    
    private static func notifyFavoriteRemoved(_ podcastId: String) {
        NotificationCenter.default.post(name: favoriteRemovedNotification, object: nil, userInfo: ["podcastId": podcastId])
    }
    
}
