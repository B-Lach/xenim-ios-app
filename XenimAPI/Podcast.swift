//
//  Podcast.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

public struct Artwork {
    public let thumb180Url: URL?
    public let thumb800Url: URL?
    public let thumb1600Url: URL?
    public let thumb3000Url: URL?
}

public class Podcast : NSObject, Comparable {
    
    public let id: String
    public let name: String
    public let podcastDescription: String
    public let artwork: Artwork
    
    public let subtitle: String?
    public let email: String?
    public let websiteUrl: URL?
    
    public let feedUrl: URL?
    // do not forget to enable them in Info.plist
    static private let subscribeURLSchemes = ["Castro" : "castro://subscribe/", "Downcast" : "downcast://", "Instacast" : "instacast://", "Overcast" : "overcast://x-callback-url/add?url=", "PocketCasts" : "pktc://subscribe/", "Podcasts" : "pcast://", "Podcat" : "podcat://"]
    public var subscribeURLSchemesDictionary: [String:URL]? {
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
    
    public let twitterUsername: String?
    public var twitterURL: URL? {
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

public func ==(x: Podcast, y: Podcast) -> Bool { return x.id == y.id }
public func <(x: Podcast, y: Podcast) -> Bool { return x.name < y.name }

