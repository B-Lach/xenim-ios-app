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
    var id: String
    var livedate: NSDate
    var podcast: Podcast?
    var podcastName: String
    var streamurl: String
    var title: String
    var url: String
    
    init(duration: String, id: String, livedate: String, podcast: String, streamurl: String, title: String, url: String) {
        if let durationNumber = Int(duration) {
            self.duration = durationNumber
        } else {
            self.duration = 0
        }
        self.id = id
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-DD HH:mm:ss"
        if let date = dateFormatter.dateFromString(livedate) {
            self.livedate = date
        } else {
            self.livedate = NSDate()
        }
        
        self.podcastName = podcast
        self.streamurl = streamurl
        self.title = title
        self.url = url
    }
    
}