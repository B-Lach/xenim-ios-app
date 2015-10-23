//
//  LifeEvent.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

class Event {

    var duration: Int
    var livedate: NSDate?
    var podcastSlug: String
    var streamurl: String
    var imageurl: String
    var description: String
    var title: String
    var url: String
    
    init(duration: String, livedate: String, podcastSlug: String, streamurl: String, imageurl: String, description: String, title: String, url: String) {
        
        if let durationNumber = Int(duration) {
            self.duration = durationNumber
        } else {
            self.duration = 0
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(name: "Europe/Berlin")
        self.livedate = formatter.dateFromString(livedate)
        
        self.podcastSlug = podcastSlug
        self.streamurl = streamurl
        self.imageurl = imageurl
        self.description = description
        self.title = title
        self.url = url
    }
    
}