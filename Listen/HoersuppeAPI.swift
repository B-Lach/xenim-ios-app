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
            "action": "getLive",
            "count": "\(count)"
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    let data = json["data"]
                    if data != nil {
                        for i in 0 ..< data.count {
                            
                            let event = json["data"][i]
                            
                            let duration = event["duration"].string!
                            let id = event["id"].string!
                            let livedate = event["livedate"].string!
                            let podcast = event["podcast"].string!
                            let streamurl = event["streamurl"].string!
                            let title = event["title"].string!
                            let url = event["url"].string!
                            
                            events.append(Event(duration: duration, id: id, livedate: livedate, podcast: podcast, streamurl: streamurl, title: title, url: url))
                        }
                    }
                    onComplete(events: events)
                }
        }
    }
    
    static func fetchPodcastDetail(podcastName: String, onComplete: (podcast: Podcast?) -> Void) {
        let parameters = [
            "action": "getPodcastData",
            "podcast": podcastName
        ]
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let responseData = response.data {                    
                    let json = JSON(data: responseData)
                    let podcast = json["data"]
                    if podcast != nil {                        
                        onComplete(podcast: Podcast(name: podcast["title"].string!, subtitle: podcast["subtitle"].string!, url: podcast["url"].string!, feedurl: podcast["feedurl"].string!, imageurl: podcast["imageurl"].string!, slug: podcast["slug"].string!, description: podcast["description"].string!))
                    } else {
                        onComplete(podcast: nil)
                    }
                }
        }
    }
}