//
//  HoersuppeAPI.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class XenimAPI : ListenAPI {
    
    static let apiBaseURL = "http://feeds.streams.demo.xenim.de/api/v1/"
    
    static func fetchUpcomingEvents(maxCount maxCount: Int? = 20, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "episode/"
        let parameters = [
            "state": "UPCOMING",
            "limit": "\(maxCount!)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                var events = [Event]()
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let objects = json["objects"]
                    
                    let serviceGroup = dispatch_group_create()
                    
                    for eventJSON in objects.array! {
                        dispatch_group_enter(serviceGroup)
                        eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                            if event != nil {
                                // this has to be thread safe
                                objc_sync_enter(events)
                                events.append(event!)
                                objc_sync_exit(events)
                                dispatch_group_leave(serviceGroup)
                            }
                        })
                    }
                    
                    // only continue if all calls from before finished
                    dispatch_group_wait(serviceGroup, DISPATCH_TIME_FOREVER)
                }
                onComplete(events: events)
        }
    }
    
    static func fetchEventById(eventId: String, onComplete: (event: Event?) -> Void){
        let url = apiBaseURL + "episode/\(eventId)/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                if let responseData = response.data {
                    let eventJSON = JSON(data: responseData)
                    eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                        onComplete(event: event)
                    })
                } else {
                    onComplete(event: nil)
                }
        }
    }
    
    static func fetchLiveEvents(onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "episode/"
        let parameters = [
            "state": "RUNNING"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                var events = [Event]()
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let objects = json["objects"]
                    
                    let serviceGroup = dispatch_group_create()
                    
                    for eventJSON in objects.array! {
                        dispatch_group_enter(serviceGroup)
                        eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                            if event != nil {
                                // this has to be thread safe
                                objc_sync_enter(events)
                                events.append(event!)
                                objc_sync_exit(events)
                                dispatch_group_leave(serviceGroup)
                            }
                        })
                    }
                    
                    // only continue if all calls from before finished
                    dispatch_group_wait(serviceGroup, DISPATCH_TIME_FOREVER)
                }
                onComplete(events: events)
        }
    }
    
    static func fetchPodcastUpcomingEvents(podcastId: String, maxCount: Int?, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "podcast/\(podcastId)/episodes/"
        let parameters = [
            "state": "UPCOMING",
            "limit": "\(maxCount!)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                var events = [Event]()
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let objects = json["objects"]
                    
                    let serviceGroup = dispatch_group_create()
                    
                    for eventJSON in objects.array! {
                        dispatch_group_enter(serviceGroup)
                        eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                            if event != nil {
                                // this has to be thread safe
                                objc_sync_enter(events)
                                events.append(event!)
                                objc_sync_exit(events)
                                dispatch_group_leave(serviceGroup)
                            }
                        })
                    }
                    
                    // only continue if all calls from before finished
                    dispatch_group_wait(serviceGroup, DISPATCH_TIME_FOREVER)
                }
                onComplete(events: events)
        }
    }
    
    static func fetchPodcastById(podcastId: String, onComplete: (podcast: Podcast?) -> Void){
        let url = apiBaseURL + "podcast/\(podcastId)/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                if let responseData = response.data {
                    let podcastJSON = JSON(data: responseData)
                    
                    if let podcast = podcastFromJSON(podcastJSON) {
                        onComplete(podcast: podcast)
                    } else {
                        onComplete(podcast: nil)
                    }
                } else {
                    onComplete(podcast: nil)
                }
        }
    }

    static func fetchAllPodcasts(onComplete: (podcasts: [Podcast]) -> Void){
        let url = apiBaseURL + "podcast/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                var podcasts = [Podcast]()
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let objects = json["objects"]
                    
                    for podcastJSON in objects.array! {
                        if let podcast = podcastFromJSON(podcastJSON) {
                            podcasts.append(podcast)
                        }
                    }
                }
                onComplete(podcasts: podcasts)
        }
    }
    
    // MARK: - Helpers
    
    static func podcastFromJSON(podcastJSON: JSON) -> Podcast? {
        let id = podcastJSON["id"].stringValue
        let name = podcastJSON["name"].stringValue
        let podcastDescription = podcastJSON["description"].stringValue
        
        let artwork = Artwork(originalUrl: podcastJSON["artwork_original_url"].URL, thumb150Url: podcastJSON["artwork_thumb_url"].URL)
        let subtitle = podcastJSON["subtitle"].stringValue
        let podcastXenimWebUrl = podcastJSON["absolute_url"].URL
        let websiteUrl = podcastJSON["website_url"].URL
        let ircUrl = podcastJSON["irc_url"].URL
        let webchatUrl = podcastJSON["webchat_url"].URL
        let feedUrl = podcastJSON["feed_url"].URL
        let twitterUsername = podcastJSON["twitter_handle"].stringValue
        let flattrId: String? = nil
        let email = podcastJSON["email"].stringValue
        
        if id != "" && name != "" && podcastDescription != "" {
            return Podcast(id: id, name: name, description: podcastDescription, artwork: artwork, subtitle: subtitle, podcastXenimWebUrl: podcastXenimWebUrl, websiteUrl: websiteUrl, ircUrl: ircUrl, webchatUrl: webchatUrl, feedUrl: feedUrl, email: email, twitterUsername: twitterUsername, flattrId: flattrId)
        } else {
            return nil
        }
    }
    
    static func eventFromJSON(eventJSON: JSON, onComplete: (event: Event?) -> Void) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let absoluteUrl = eventJSON["absolute_url"].URL
        let begin = formatter.dateFromString(eventJSON["begin"].stringValue)
        let description = eventJSON["description"].stringValue.trim()
        let end = formatter.dateFromString(eventJSON["end"].stringValue)
        let id = eventJSON["id"].stringValue
        let podcastId = eventJSON["podcast"].stringValue.characters.split{$0 == "/"}.map(String.init).last
        let shownotes = eventJSON["shownotes"].stringValue
        let title = eventJSON["title"].stringValue.trim()
        
        var status: Status? = nil
        switch eventJSON["status"].stringValue {
            case "RUNNING": status = .RUNNING
            case "UPCOMING": status = .UPCOMING
            case "ARCHIVED": status = .ARCHIVED
            default: break
        }
        
        var streams = [Stream]()
        for streamJSON in eventJSON["streams"].array! {
            let bitrate = streamJSON["bitrate"].stringValue
            let codec = streamJSON["bitrate"].stringValue
            if let url = streamJSON["url"].URL {
                streams.append(Stream(codec: codec, bitrate: bitrate, url: url))
            }
        }
        
        if podcastId != nil && podcastId != "" {
            fetchPodcastById(podcastId!) { (podcast) -> Void in
                // only add this event to the list if it has a minimum number
                // of attributes set
                if id != "" && begin != nil && end != nil && title != "" && status != nil && podcast != nil {
                    let event = Event(id: id, title: title, status: status!, begin: begin!, end: end!, podcast: podcast!, eventXenimWebUrl: absoluteUrl, streams: streams, shownotes: shownotes, description: description)
                    onComplete(event: event)
                } else {
                    onComplete(event: nil)
                }
            }
        } else {
            onComplete(event: nil)
        }

    }
}