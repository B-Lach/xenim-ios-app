//
//  Podcast.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

struct Artwork {
    let originalUrl: NSURL?
    let thumb150Url: NSURL?
    let thumb180Url: NSURL?
    init(originalUrl: NSURL?, thumb150Url: NSURL?, thumb180Url: NSURL?) {
        self.originalUrl = originalUrl
        self.thumb150Url = thumb150Url
        self.thumb180Url = thumb180Url
    }
}

class Podcast : NSObject, Comparable {
    
    let id: String
    let name: String
    let podcastDescription: String
    let artwork: Artwork

    let subtitle: String?
    let email: String?
    let podcastXenimWebUrl: NSURL?
    let websiteUrl: NSURL?
    let ircUrl: NSURL?
    var ircChannel: String? {
        get {
            if let url = ircUrl {
                return url.lastPathComponent
            }
            return nil
        }
    }
    var ircServer: String? {
        get {
            if let url = ircUrl {
                return url.host
            }
            return nil
        }
    }
    
    
    let webchatUrl: NSURL?
    
    let feedUrl: NSURL?
    // do not forget to enable them in Info.plist
    static private let subscribeURLSchemes = ["Castro" : "castro://subscribe/", "Downcast" : "downcast://", "Instacast" : "instacast://", "Overcast" : "overcast://x-callback-url/add?url=", "PocketCasts" : "pktc://subscribe/", "Podcasts" : "pcast://", "Podcat" : "podcat://"]
    var subscribeURLSchemesDictionary: [String:NSURL]? {
        get {
            if let feedUrl = feedUrl {
                var subscribeClients = [String:NSURL]()
                for client in Podcast.subscribeURLSchemes {
                    let urlScheme = client.1
                    let clientName = client.0
                    if let subscribeURL = NSURL(string: urlScheme + feedUrl.description) {
                        subscribeClients[clientName] = subscribeURL
                    }
                }
                return subscribeClients
            } else {
                return nil
            }
        }
    }

    let twitterUsername: String?
    var twitterURL: NSURL? {
        get {
            if let username = twitterUsername {
                return NSURL(string: "https://twitter.com/\(username)")
            } else {
                return nil
            }

        }
    }
    let flattrId: String?
    var flattrURL: NSURL? {
        get {
            if let flattrId = self.flattrId {
                return NSURL(string: "https://flattr.com/profile/\(flattrId)")
            } else {
                return nil
            }
            
        }
    }
    
    init(id: String, name: String, description: String, artwork: Artwork, subtitle: String?, podcastXenimWebUrl: NSURL?, websiteUrl: NSURL?, ircUrl: NSURL?, webchatUrl: NSURL?, feedUrl: NSURL?, email: String?, twitterUsername: String?, flattrId: String?) {
        
        self.id = id
        self.name = name
        self.podcastDescription = description
        self.artwork = artwork
        self.subtitle = subtitle
        self.podcastXenimWebUrl = podcastXenimWebUrl
        self.websiteUrl = websiteUrl
        self.ircUrl = ircUrl
        self.webchatUrl = webchatUrl
        self.feedUrl = feedUrl
        self.twitterUsername = twitterUsername
        self.flattrId = flattrId
        self.email = email
        
        super.init()
    }
    
    /*
        returns days until next event
        returns -1 if there is no event scheduled in the future
    */
    func getDaysUntilNextEvent(onComplete: (days: Int) -> Void) {
        // fetch upcoming events
        XenimAPI.fetchPodcastUpcomingEvents(self.id, maxCount: 1) { (events) -> Void in
            if events.first != nil && events.first!.isUpcoming() {
                // calculate in how many days this event takes place
                let cal = NSCalendar.currentCalendar()
                let today = cal.startOfDayForDate(NSDate())
                let diff = cal.components(NSCalendarUnit.Day,
                    fromDate: today,
                    toDate: events.first!.begin,
                    options: NSCalendarOptions.WrapComponents )
                onComplete(days: diff.day)
            } else {
                onComplete(days: -1)
            }
        }
    }
    
    func daysUntilNextEventString(onComplete: (string: String) -> Void) {
        getDaysUntilNextEvent { (days) -> Void in
            if days < 0 {
                // no event scheduled
                let noEventString = String(format: NSLocalizedString("favorite_tableviewcell_no_event_scheduled", value: "Nothing scheduled", comment: "Tells the user that there is no event scheduled in the future"))
                onComplete(string: noEventString)
            } else if days == 0 {
                // the event is today
                onComplete(string: NSLocalizedString("Today", value: "Today", comment: "Today").lowercaseString)
            } else {
                // the event is in the future
                let diffDaysString = String(format: NSLocalizedString("favorite_tableviewcell_diff_date_string", value: "in %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), days)
                onComplete(string: diffDaysString)
            }
        }
    }
}


// MARK: Comparable

func ==(x: Podcast, y: Podcast) -> Bool { return x.id == y.id }
func <(x: Podcast, y: Podcast) -> Bool { return x.name < y.name }

