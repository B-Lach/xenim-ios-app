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
    
    static func fetchEvents(count count: Int, onComplete: (liveEvents: [LiveEvent]) -> Void) {
        var liveEvents = [LiveEvent]()
        let parameters = [
            "action": "getLive",
            "count": "\(count)"
        ]
        let url = "http://hoersuppe.de/api/"
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
                            
                            liveEvents.append(LiveEvent(duration: duration, id: id, livedate: livedate, podcast: podcast, streamurl: streamurl, title: title, url: url))
                        }
                    }
                    onComplete(liveEvents: liveEvents)
                }
        }
    }
    
    static func fetchPodcastDetail(podcastName: String) -> Podcast? {
        return nil
    }
}