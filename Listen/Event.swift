//
//  LifeEvent.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

class Event : NSObject {

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
    var podcastDescription: String
    var title: String
    var url: String
    
    //value between 0 and 1
    var progress: Float = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("progressUpdate", object: self, userInfo: nil)
        }
    }
    var timer : NSTimer? // timer to update the progress periodically
    let updateInterval: NSTimeInterval = 60
    
    init?(duration: String, livedate: String, podcastSlug: String, streamurl: String, imageurl: String, podcastDescription: String, title: String, url: String) {
        
        self.podcastSlug = podcastSlug
        self.podcastDescription = podcastDescription
        self.title = title
        self.url = url
        
        super.init()
        
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
        
        // setup timer to update progressbar every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("timerTicked"), userInfo: nil, repeats: true)
        timerTicked()
    }
    
    deinit {
        timer?.invalidate()
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
        let now = NSDate()
        let nowWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: now).weekOfYear
        let eventWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: livedate).weekOfYear
        return nowWeek == eventWeek
    }
    
    @objc func timerTicked() {
        // update progress value
        let timePassed = NSDate().timeIntervalSinceDate(livedate)
        let factor = (Float)(timePassed/duration)
        progress = min(max(factor, 0.0), 1.0)
    }
    
    func equals(otherEvent: Event) -> Bool {
        return podcastSlug == otherEvent.podcastSlug && livedate.timeIntervalSinceDate(otherEvent.livedate) == 0
    }
    
}