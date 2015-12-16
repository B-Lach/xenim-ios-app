//
//  Podcast.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

struct Artwork {
    let originalUrl: NSURL?
    let thumb150Url: NSURL?
    init(originalUrl: NSURL?, thumb150Url: NSURL?) {
        self.originalUrl = originalUrl
        self.thumb150Url = thumb150Url
    }
}

class Podcast : NSObject {
    
    let id: String
    let name: String
    let podcastDescription: String
    let artwork: Artwork

    let subtitle: String?
    let podcastXenimWebUrl: NSURL?
    let websiteUrl: NSURL?
    let ircUrl: NSURL?
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
    
    init(id: String, name: String, description: String, artwork: Artwork, subtitle: String?, podcastXenimWebUrl: NSURL?, websiteUrl: NSURL?, ircUrl: NSURL?, webchatUrl: NSURL?, feedUrl: NSURL?, twitterUsername: String?, flattrId: String?) {
        
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
        
        super.init()
    }
    
}