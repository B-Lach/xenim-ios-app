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
    let url: URL
    init(codec: String, bitrate: String, url: URL) {
        self.codec = codec
        self.bitrate = bitrate
        self.url = url
    }
}

enum Status {
    case running
    case upcoming
    case archived
    case expired
}

class Event : NSObject {
    
    let id: String
    let status: Status
    let begin: Date
    let end: Date?
    let podcast: Podcast
    
    // return podcast name as event title if title is not set
    var title: String?
    let eventXenimWebUrl: URL?
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
    var streamUrl: URL? {
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
    var duration: TimeInterval? {
        get {
            return end?.timeIntervalSince(begin)
        }
    }
    //value between 0 and 1
    var progress: Float {
        if let duration = duration {
            let timePassed = Date().timeIntervalSince(begin)
            let factor = (Float)(timePassed/duration)
            return min(max(factor, 0.0), 1.0)
        } else {
            return 0
        }
    }
    
    init(id: String, status: Status, begin: Date, end: Date?, podcast: Podcast, title: String?, eventXenimWebUrl: URL?, streams: [Stream], shownotes: String?, description: String?, listeners: Int?) {
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
    
    func fetchCurrentListeners(_ onComplete: (listeners: Int?) -> Void) {
        XenimAPI.fetchEvent(eventId: id) { (event) -> Void in
            if let event = event {
                onComplete(listeners: event.listeners)
                self.listeners = event.listeners
            }
        }
    }

    func isLive() -> Bool {
        return status == Status.running
    }
    
    /*
        An event is upcoming if it is scheduled for today or in the future.
        It can be in the past, but only if it is still today.
    */
    func isUpcoming() -> Bool {
        if status == Status.upcoming {
            let now = Date()
            let calendar = Calendar.current
            
            // check if the begin date is in the future or today
            if now.compare(begin) == ComparisonResult.orderedAscending || calendar.isDateInToday(begin) {
               return true
            }
        }
        return false
    }
    
    func isUpcomingToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(begin) && isUpcoming()
    }
    
    func isUpcomingTomorrow() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInTomorrow(begin) && isUpcoming()
    }
    
    func isUpcomingThisWeek() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let nowWeek = calendar.components(Calendar.Unit.weekOfYear, from: now).weekOfYear
        let eventWeek = calendar.components(Calendar.Unit.weekOfYear, from: begin).weekOfYear
        return nowWeek == eventWeek && isUpcoming()
    }
    
    func equals(_ otherEvent: Event) -> Bool {
        return id == otherEvent.id
    }
    
}
