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
    let thumb180Url: URL?
    let thumb800Url: URL?
    let thumb1600Url: URL?
    let thumb3000Url: URL?
}

class Podcast : NSObject, Comparable {
    
    let id: String
    let name: String
    let podcastDescription: String
    let artwork: Artwork

    let subtitle: String?
    let email: String?
    let websiteUrl: URL?
    
    let feedUrl: URL?
    // do not forget to enable them in Info.plist
    static private let subscribeURLSchemes = ["Castro" : "castro://subscribe/", "Downcast" : "downcast://", "Instacast" : "instacast://", "Overcast" : "overcast://x-callback-url/add?url=", "PocketCasts" : "pktc://subscribe/", "Podcasts" : "pcast://", "Podcat" : "podcat://"]
    var subscribeURLSchemesDictionary: [String:URL]? {
        get {
            if let feedUrl = feedUrl {
                var subscribeClients = [String:URL]()
                for client in Podcast.subscribeURLSchemes {
                    let urlScheme = client.1
                    let clientName = client.0
                    if let subscribeURL = URL(string: urlScheme + feedUrl.description) {
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
    var twitterURL: URL? {
        get {
            if let username = twitterUsername {
                return URL(string: "https://twitter.com/\(username)")
            } else {
                return nil
            }

        }
    }
    
    init(id: String, name: String, description: String, artwork: Artwork, subtitle: String?, websiteUrl: URL?, feedUrl: URL?, email: String?, twitterUsername: String?) {
        
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

