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
    let thumb180Url: NSURL?
    let thumb1300Url: NSURL?
    let thumb800Url: NSURL?
    init(thumb180Url: NSURL?, thumb800Url: NSURL?, thumb1300Url: NSURL?) {
        self.thumb180Url = thumb180Url
        self.thumb800Url = thumb800Url
        self.thumb1300Url = thumb1300Url
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
    
}


// MARK: Comparable

func ==(x: Podcast, y: Podcast) -> Bool { return x.id == y.id }
func <(x: Podcast, y: Podcast) -> Bool { return x.name < y.name }

