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

    var duration: NSTimeInterval = 0 // in seconds
    var livedate = NSDate()
    var endDate: NSDate {
        get {
            return livedate.dateByAddingTimeInterval(duration) // event.duration is minutes
        }
    }
    var podcastSlug: String
    var streamurl = NSURL(string: "")!
    var imageurl = NSURL(string: "")!
    var description: String
    var title: String
    var url: String
    
    init?(duration: String, livedate: String, podcastSlug: String, streamurl: String, imageurl: String, description: String, title: String, url: String) {
        
        self.podcastSlug = podcastSlug
        self.description = description
        self.title = title
        self.url = url
        
        if let streamurl = NSURL(string: streamurl) {
            self.streamurl = streamurl
        } else {
            return nil
        }
        if let imageurl = NSURL(string: imageurl) {
            self.imageurl = imageurl
        } else {
            return nil
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(name: "Europe/Berlin")
        if let date = formatter.dateFromString(livedate) {
            self.livedate = date
        } else {
            return nil // fail initialization
        }
        
        if let durationNumber = Int(duration) {
            self.duration = (Double)(durationNumber * 60)
        } else {
            return nil
        }
    }

    func isLive() -> Bool {
        let now = NSDate()
        return livedate.earlierDate(now) == livedate && endDate.laterDate(now) == endDate
    }
    
    func isFinished() -> Bool {
        let now = NSDate()
        return endDate.earlierDate(now) == endDate
    }
    
    func isToday() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInToday(livedate)
    }
    
    func isTomorrow() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInTomorrow(livedate)
    }
    
    func isThisWeek() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInWeekend(livedate)
    }
    
    // return progress as a value between 0 and 1
    func progress() -> Double {
        let timePassed = NSDate().timeIntervalSinceDate(livedate)
        let factor = (Double)(timePassed/duration)
        return min(max(factor, 0.0), 1.0)
    }
    
}