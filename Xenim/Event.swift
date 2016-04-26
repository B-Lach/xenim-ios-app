//
//  LifeEvent.swift
//  Xenim
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
    var title: String?
    let eventXenimWebUrl: NSURL?
    let eventDescription: String?
    let shownotes: String?
    var streams = [Stream]()
    var listeners: Int? {
        didSet {
            // only allow listeners count >= 0
            if listeners != nil && listeners! < 0 {
                listeners = 0
            }
        }
    }
    // returns a supported streamUrl or nil
    var streamUrl: NSURL? {
        get {
            let supportedCodecs = ["mp3", "aac"]
            // try to find a stream that is supported by ios
            for stream in streams {
                if supportedCodecs.contains(stream.codec) {
                    return stream.url
                }
            }
            return nil
        }
    }
    
    // in seconds    
    var duration: NSTimeInterval? {
        get {
            return end?.timeIntervalSinceDate(begin)
        }
    }
    //value between 0 and 1
    var progress: Float {
        if let duration = duration {
            let timePassed = NSDate().timeIntervalSinceDate(begin)
            let factor = (Float)(timePassed/duration)
            return min(max(factor, 0.0), 1.0)
        } else {
            return 0
        }
    }
    
    init(id: String, status: Status, begin: NSDate, end: NSDate?, podcast: Podcast, title: String?, eventXenimWebUrl: NSURL?, streams: [Stream], shownotes: String?, description: String?, listeners: Int?) {
        self.id = id
        self.title = title
        self.status = status
        self.begin = begin
        self.end = end
        self.podcast = podcast
        self.eventXenimWebUrl = eventXenimWebUrl
        self.streams = streams
        self.shownotes = shownotes
        self.eventDescription = description
        self.listeners = listeners
        
        super.init()
    }
    
    func fetchCurrentListeners(onComplete: (listeners: Int?) -> Void) {
        XenimAPI.fetchEvent(eventId: id) { (event) -> Void in
            if let event = event {
                onComplete(listeners: event.listeners)
                self.listeners = event.listeners
            }
        }
    }

    func isLive() -> Bool {
        return status == Status.RUNNING
    }
    
    /*
        An event is upcoming if it is scheduled for today or in the future.
        It can be in the past, but only if it is still today.
    */
    func isUpcoming() -> Bool {
        if status == Status.UPCOMING {
            let now = NSDate()
            let calendar = NSCalendar.currentCalendar()
            
            // check if the begin date is in the future or today
            if now.compare(begin) == NSComparisonResult.OrderedAscending || calendar.isDateInToday(begin) {
               return true
            }
        }
        return false
    }
    
    func isUpcomingToday() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInToday(begin) && isUpcoming()
    }
    
    func isUpcomingTomorrow() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInTomorrow(begin) && isUpcoming()
    }
    
    func isUpcomingThisWeek() -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        let nowWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: now).weekOfYear
        let eventWeek = calendar.components(NSCalendarUnit.WeekOfYear, fromDate: begin).weekOfYear
        return nowWeek == eventWeek && isUpcoming()
    }
    
    func equals(otherEvent: Event) -> Bool {
        return id == otherEvent.id
    }
    
}