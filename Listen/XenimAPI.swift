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
    
    static let apiBaseURL = "http://hoersuppe.de/api/"
    
    static func fetchEventById(eventId: String, onComplete: (event: Event?) -> Void) {
    
    }
    
    static func fetchScheduledEvents(maxCount maxCount: Int?, startDate: NSDate? = NSDate(), endDate: NSDate?, onComplete: (event: [Event]) -> Void) {
    
    }
    
    static func fetchLiveEvents(onComplete: (event: [Event]) -> Void) {
    
    }
    
    static func fetchPodcastById(podcastId: String, onComplete: (podcast: Podcast?) -> Void) {
    
    }
    
    static func fetchPodcastScheduledEvents(podcastId: String, maxCount: Int? = 3, startDate: NSDate? = NSDate(), onComplete: (event: [Event]) -> Void) {
    
    }
    
    static func fetchAllPodcasts(onComplete: (podcasts: [Podcast]) -> Void) {
    
    }
    
    
    
    
    
    
    
    
    
    
    
    static func fetchEvents(count count: Int, onComplete: (events: [Event]) -> Void) {
        var events = [Event]()
        let parameters = [
            "action": "getUpcomingPodlive",
            "count": "\(count)"
        ]
        Alamofire.request(.GET, apiBaseURL, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let eventJSON = json["data"][i]
                            
                            let duration = eventJSON["duration"].stringValue
                            let livedate = eventJSON["liveDate"].stringValue
                            let imageurl = eventJSON["imageUrl"].stringValue
                            let slug = eventJSON["podcast"].stringValue
                            let description = eventJSON["description"].stringValue.trim()
                            let streamurl = eventJSON["streamUrl"].stringValue
                            let title = eventJSON["eventTitle"].stringValue.trim()
                            let url = eventJSON["url"].stringValue
                            
                            if let event = Event(duration: duration, livedate: livedate, podcastSlug: slug, streamurl: streamurl, imageurl: imageurl, podcastDescription: description, title: title, url: url) {
                                events.append(event)
                            } else {
                                print("dropping event.")
                            }
                            
                        }
                    }
                    onComplete(events: events)
                }
        }
    }
    
    static func fetchPodcastDetail(podcastSlug: String, onComplete: (podcast: Podcast?) -> Void) {
        let parameters = [
            "action": "getPodcastData",
            "podcast": podcastSlug
        ]
        Alamofire.request(.GET, apiBaseURL, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {                    
                    let json = JSON(data: responseData)
                    let podcastJSON = json["data"]
                    
                    let name = podcastJSON["title"].stringValue.trim()
                    let subtitle = podcastJSON["subtitle"].stringValue.trim()
                    let url = podcastJSON["url"].stringValue
                    let feedurl = podcastJSON["feedurl"].stringValue
                    let imageurl = podcastJSON["imageurl"].stringValue
                    let slug = podcastJSON["slug"].stringValue
                    let description = podcastJSON["description"].stringValue.trim()
                    let chatServer = podcastJSON["chat_server"].stringValue
                    let chatChannel = podcastJSON["chat_channel"].stringValue
                    let webchatUrl = podcastJSON["chat_url"].stringValue
                    let twitterUsername = podcastJSON["contact"]["twitter"].stringValue
                    let email = podcastJSON["contact"]["email"].stringValue
                    let flattrID = podcastJSON["flattrid"].stringValue
                    
                    let podcast = Podcast(name: name, subtitle: subtitle, url: url, feedurl: feedurl, imageurl: imageurl, slug: slug, podcastDescription: description, chatServer: chatServer, chatChannel: chatChannel, webchatUrl: webchatUrl, twitterUsername: twitterUsername, email: email, flattrID: flattrID)
                    onComplete(podcast: podcast)
                }
        }
    }
    
    static func fetchPodcastNextLiveEvents(podcastSlug: String, count: Int, onComplete: (events: [Event]) -> Void) {
        var events = [Event]()
        let parameters = [
            "action": "getPodcastLive",
            "podcast": podcastSlug,
            "count": "\(count)"
        ]
        Alamofire.request(.GET, apiBaseURL, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let eventJSON = json["data"][i]
                            
                            // important: there is no description or imageurl in this API call response!
                            
                            let duration = eventJSON["duration"].stringValue
                            let livedate = eventJSON["livedate"].stringValue
                            let slug = eventJSON["podcast"].stringValue
                            let streamurl = eventJSON["streamurl"].stringValue
                            let title = eventJSON["title"].stringValue.trim()
                            let url = eventJSON["url"].stringValue
                            
                            // TODO imageurl fix, as this is not how this initializer should be used
                            
                            if let event = Event(duration: duration, livedate: livedate, podcastSlug: slug, streamurl: streamurl, imageurl: "", podcastDescription: "", title: title, url: url) {
                                events.append(event)
                            } else {
                                print("dropping event.")
                            }
                            
                        }
                    }
                    onComplete(events: events)
                }
        }
    }
    
    static func fetchAllPodcasts(onComplete: (podcasts: [String:String]) -> Void) {
        var podcasts = [String:String]()
        let parameters = [
            "action": "getPodcasts"
        ]
        Alamofire.request(.GET, apiBaseURL, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let podcast = json["data"][i]
                            podcasts[podcast["slug"].stringValue] = podcast["title"].stringValue
                        
                        }
                    }
                    onComplete(podcasts: podcasts)
                }
        }
    }
}