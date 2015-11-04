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

class HoersuppeAPI {
    
    static let url = "http://hoersuppe.de/api/"
    
    static func fetchEvents(count count: Int, onComplete: (events: [Event]) -> Void) {
        var events = [Event]()
        let parameters = [
            "action": "getUpcomingPodlive",
            "count": "\(count)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let eventJSON = json["data"][i]
                            
                            let duration = eventJSON["duration"].string!
                            let livedate = eventJSON["liveDate"].string!
                            let imageurl = eventJSON["imageUrl"].string!
                            let slug = eventJSON["podcast"].string!
                            let description = eventJSON["description"].string!
                            let streamurl = eventJSON["streamUrl"].string!
                            let title = eventJSON["eventTitle"].string!
                            let url = eventJSON["url"].string!
                            
                            if let event = Event(duration: duration, livedate: livedate, podcastSlug: slug, streamurl: streamurl, imageurl: imageurl, description: description, title: title, url: url) {
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
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {                    
                    let json = JSON(data: responseData)
                    let podcastJSON = json["data"]
                    
                    let name = podcastJSON["title"].string!
                    let subtitle = podcastJSON["subtitle"].string!
                    let url = podcastJSON["url"].string!
                    let feedurl = podcastJSON["feedurl"].string!
                    let imageurl = podcastJSON["imageurl"].string!
                    let slug = podcastJSON["slug"].string!
                    let description = podcastJSON["description"].string!
                    
                    if let podcast = Podcast(name: name, subtitle: subtitle, url: url, feedurl: feedurl, imageurl: imageurl, slug: slug, description: description) {
                        onComplete(podcast: podcast)
                    } else {
                        onComplete(podcast: nil)
                    }
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
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let eventJSON = json["data"][i]
                            
                            // important: there is no description or imageurl in this API call response!
                            
                            let duration = eventJSON["duration"].string!
                            let livedate = eventJSON["livedate"].string!
                            let slug = eventJSON["podcast"].string!
                            let streamurl = eventJSON["streamurl"].string!
                            let title = eventJSON["title"].string!
                            let url = eventJSON["url"].string!
                            
                            // TODO imageurl fix, as this is not how this initializer should be used
                            
                            if let event = Event(duration: duration, livedate: livedate, podcastSlug: slug, streamurl: streamurl, imageurl: "", description: "", title: title, url: url) {
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
}