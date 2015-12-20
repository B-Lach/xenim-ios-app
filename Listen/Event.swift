//
//  LifeEvent.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

struct Stream {
    let codec: String
    let bitrate: String
    let url: NSURL
    init(codec: String, bitrate: String, url: NSURL) {
        self.codec = codec
        self.bitrate = bitrate
        self.url = url
    }
}

enum Status {
    case RUNNING
    case UPCOMING
    case ARCHIVED
    case EXPIRED
}

class Event : NSObject {
    
    let id: String
    let status: Status
    let begin: NSDate
    let end: NSDate?
    let podcast: Podcast
    
    // return podcast name as event title if title is not set
    private var ptitle: String? = nil
    var title: String? {
        get {
            if self.ptitle == nil {
                return podcast.name
            } else {
                return ptitle
            }
        }
    }
    let eventXenimWebUrl: NSURL?
    let eventDescription: String?
    var listeners: Int? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("listenersUpdate", object: self, userInfo: nil)
        }
    }
    let shownotes: String?
    var streams = [Stream]()
    
    // in seconds    
    var duration: NSTimeInterval? {
        get {
            return end?.timeIntervalSinceDate(begin)
        }
    }
    //value between 0 and 1
    var progress: Float = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("progressUpdate", object: self, userInfo: nil)
        }
    }
    var timer : NSTimer? // timer to update the progress periodically
    let updateInterval: NSTimeInterval = 60
    
    init(id: String, status: Status, begin: NSDate, end: NSDate?, podcast: Podcast, title: String?, eventXenimWebUrl: NSURL?, streams: [Stream], shownotes: String?, description: String?) {
        self.id = id
        self.ptitle = title
        self.status = status
        self.begin = begin
        self.end = end
        self.podcast = podcast
        self.eventXenimWebUrl = eventXenimWebUrl
        self.streams = streams
        self.shownotes = shownotes
        self.eventDescription = description
        
        super.init()
        
        if isLive() {
            // setup timer to update progressbar every minute
            // remember to invalidate timer as soon this view gets cleared otherwise
            // this will cause a memory cycle
            timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("timerTicked"), userInfo: nil, repeats: true)
            timerTicked()
        }
    }
    
    deinit {
        timer?.invalidate()
    }

    func isLive() -> Bool {
        return status == Status.RUNNING
    }
    
    func isToday() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInToday(begin)
    }
    
    func isTomorrow() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInTomorrow(begin)
    }
    
    func isThisWeek() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        let nowWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: now).weekOfYear
        let eventWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: begin).weekOfYear
        return nowWeek == eventWeek
    }
    
    @objc func timerTicked() {
        if let duration = duration {
            // update progress value
            let timePassed = NSDate().timeIntervalSinceDate(begin)
            let factor = (Float)(timePassed/duration)
            progress = min(max(factor, 0.0), 1.0)
        }

        // update listeners
        XenimAPI.fetchEventById(id) { (event) -> Void in
            self.listeners = event?.listeners
        }
    }
    
    func equals(otherEvent: Event) -> Bool {
        return id == otherEvent.id
    }
    
}