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
    let websiteUrl: NSURL?
    
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
    
    init(id: String, name: String, description: String, artwork: Artwork, subtitle: String?, websiteUrl: NSURL?, feedUrl: NSURL?, email: String?, twitterUsername: String?) {
        
        self.id = id
        self.name = name
        self.podcastDescription = description
        self.artwork = artwork
        self.subtitle = subtitle
        self.websiteUrl = websiteUrl
        self.feedUrl = feedUrl
        self.twitterUsername = twitterUsername
        self.email = email
        
        super.init()
    }
    
}


// MARK: Comparable

func ==(x: Podcast, y: Podcast) -> Bool { return x.id == y.id }
func <(x: Podcast, y: Podcast) -> Bool { return x.name < y.name }

