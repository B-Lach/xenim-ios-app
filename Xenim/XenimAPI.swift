//
//  HoersuppeAPI.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class XenimAPI : ListenAPI {
    
    // "http://feeds.streams.demo.xenim.de/api/v1/"
    static let apiBaseURL = "http://feeds.streams.demo.xenim.de/api/v1/"
    
    static func fetchUpcomingEvents(maxCount maxCount: Int? = 20, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "episode/"
        let parameters = [
            "status": "UPCOMING",
            "limit": "\(maxCount!)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                handleMultipleEventsResponse(response, onComplete: onComplete)
        }
    }
    
    static func fetchLiveEvents(onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "episode/"
        let parameters = [
            "status": "RUNNING"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                handleMultipleEventsResponse(response, onComplete: onComplete)
        }
    }
    
    static func fetchPodcastUpcomingEvents(podcastId: String, maxCount: Int? = 1, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "podcast/\(podcastId)/episodes/"
        let parameters = [
            "status": "UPCOMING",
            "limit": "\(maxCount!)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                handleMultipleEventsResponse(response, onComplete: onComplete)
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
                    if let objects = json["objects"].array {
                        for podcastJSON in objects {
                            if let podcast = podcastFromJSON(podcastJSON) {
                                podcasts.append(podcast)
                            }
                        }
                    }
                }
                onComplete(podcasts: podcasts)
        }
    }
    
    // MARK: - Helpers
    
    
    static func handleMultipleEventsResponse(response: Response<AnyObject, NSError>, onComplete: (events: [Event]) -> Void) {
        var events = [Event]()
        if let responseData = response.data {
            let json = JSON(data: responseData)
            if let objects = json["objects"].array {
                
                // return empty array if there is nothing to parse here
                if objects.count == 0 {
                    onComplete(events: events)
                    return
                }
                
                let blocksDispatchQueue = dispatch_queue_create("com.domain.blocksArray.sync", DISPATCH_QUEUE_CONCURRENT)
                let serviceGroup = dispatch_group_create()
                
                for eventJSON in objects {
                    dispatch_group_enter(serviceGroup)
                    eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                        dispatch_barrier_async(blocksDispatchQueue) {
                            if event != nil {
                                // this has to be thread safe
                                events.append(event!)
                            }
                            dispatch_group_leave(serviceGroup)
                        }
                    })
                }
                
                dispatch_group_notify(serviceGroup, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
                    // sort events by time as async processing appends them unordered
                    let sortedEvents = events.sort({ (event1, event2) -> Bool in
                        event1.begin.compare(event2.begin) == .OrderedAscending
                    })
                    onComplete(events: sortedEvents)
                })
            } else {
                // return empty array
                onComplete(events: events)
            }
        } else {
            // return empty array
            onComplete(events: events)
        }
    }
    
    static func podcastFromJSON(podcastJSON: JSON) -> Podcast? {
        let id = podcastJSON["id"].stringValue
        let name = podcastJSON["name"].stringValue
        let podcastDescription = podcastJSON["description"].stringValue
        
        let artworkJSON = podcastJSON["artwork"]
        let artwork = Artwork(originalUrl: artworkJSON["original"].URL, thumb150Url: artworkJSON["150"].URL, thumb180Url: artworkJSON["180"].URL)
        let subtitle: String? = podcastJSON["subtitle"].stringValue != "" ? podcastJSON["subtitle"].stringValue : nil
        let podcastXenimWebUrl: NSURL? = podcastJSON["absolute_url"].stringValue != "" ? podcastJSON["absolute_url"].URL : nil
        let websiteUrl: NSURL? = podcastJSON["website_url"].stringValue != "" ? podcastJSON["website_url"].URL : nil
        let ircUrl: NSURL? = podcastJSON["irc_url"].stringValue != "" ? podcastJSON["irc_url"].URL : nil
        let webchatUrl: NSURL? = podcastJSON["webchat_url"].stringValue != "" ? podcastJSON["webchat_url"].URL : nil
        let feedUrl: NSURL? = podcastJSON["feed_url"].stringValue != "" ? podcastJSON["feed_url"].URL : nil
        let twitterUsername: String? = podcastJSON["twitter_handle"].stringValue != "" ? podcastJSON["twitter_handle"].stringValue : nil
        let flattrId: String? = nil
        let email: String? =  podcastJSON["email"].stringValue != "" ? podcastJSON["email"].stringValue : nil
        
        if id != "" && name != "" {
            return Podcast(id: id, name: name, description: podcastDescription, artwork: artwork, subtitle: subtitle, podcastXenimWebUrl: podcastXenimWebUrl, websiteUrl: websiteUrl, ircUrl: ircUrl, webchatUrl: webchatUrl, feedUrl: feedUrl, email: email, twitterUsername: twitterUsername, flattrId: flattrId)
        } else {
            return nil
        }
    }
    
    static func eventFromJSON(eventJSON: JSON, onComplete: (event: Event?) -> Void) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let id = eventJSON["id"].stringValue
        let podcastId = eventJSON["podcast"].stringValue.characters.split{$0 == "/"}.map(String.init).last
        
        let absoluteUrl: NSURL? = eventJSON["absolute_url"].stringValue != "" ? eventJSON["absolute_url"].URL : nil
        let begin = formatter.dateFromString(eventJSON["begin"].stringValue)
        let description: String? = eventJSON["description"].stringValue.trim() != "" ? eventJSON["description"].stringValue.trim() : nil
        let end = formatter.dateFromString(eventJSON["end"].stringValue)
        let shownotes: String? = eventJSON["shownotes"].stringValue.trim() != "" ? eventJSON["shownotes"].stringValue.trim() : nil
        let title: String? = eventJSON["title"].stringValue.trim() != "" ? eventJSON["title"].stringValue.trim() : nil
        let listeners: Int? = eventJSON["listeners"].stringValue != "" ? eventJSON["listeners"].int : nil
        
        var status: Status? = nil
        switch eventJSON["status"].stringValue {
            case "RUNNING": status = .RUNNING
            case "UPCOMING": status = .UPCOMING
            case "ARCHIVED": status = .ARCHIVED
            case "EXPIRED": status = .EXPIRED
            default: break
        }
        
        var streams = [Stream]()
        if let streamsJSON = eventJSON["streams"].array {
            for streamJSON in streamsJSON {
                let bitrate = streamJSON["bitrate"].stringValue
                let codec = streamJSON["codec"].stringValue
                if let url = streamJSON["url"].URL {
                    streams.append(Stream(codec: codec, bitrate: bitrate, url: url))
                }
            }
        }

        
        if podcastId != nil {
            fetchPodcastById(podcastId!) { (podcast) -> Void in
                // only add this event to the list if it has a minimum number
                // of attributes set
                if id != "" && begin != nil && status != nil && podcast != nil {
                    let event = Event(id: id, status: status!, begin: begin!, end: end, podcast: podcast!, title: title, eventXenimWebUrl: absoluteUrl, streams: streams, shownotes: shownotes, description: description, listeners: listeners)
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