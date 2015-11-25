//
//  Podcast.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

class Podcast : NSObject {
    
    var feedurl = NSURL(string: "")!
    var imageurl = NSURL(string: "")!
    var subscribeClients: [String:NSURL] {
        get {
            var subscribeClients = [String:NSURL]()
            for client in Podcast.subscribeURLSchemes {
                let urlScheme = client.1
                let clientName = client.0
                if let subscribeURL = NSURL(string: urlScheme + feedurl.description) {
                    subscribeClients[clientName] = subscribeURL
                }
            }
            return subscribeClients
        }
    }
    var slug: String
    var subtitle: String
    var name: String // title
    var podcastDescription: String
    var url = NSURL(string: "")!
    var chatUrl: NSURL?
    var webchatUrl: NSURL?
    var email: String?
    var twitterUsername: String?
    var twitterURL: NSURL? {
        get {
            if let username = twitterUsername {
                return NSURL(string: "https://twitter.com/\(username)")
            } else {
                return nil
            }

        }
    }
    var flattrID: String?
    var flattrURL: NSURL? {
        get {
            if let flattrID = self.flattrID {
                return NSURL(string: "https://flattr.com/profile/\(flattrID)")
            } else {
                return nil
            }
            
        }
    }
    
    init?(name: String, subtitle: String, url: String, feedurl: String, imageurl: String, slug: String, podcastDescription: String, chatServer: String, chatChannel: String, webchatUrl: String, twitterUsername: String, email: String, flattrID: String) {
        self.name = name
        self.subtitle = subtitle
        self.slug = slug
        self.podcastDescription = podcastDescription
        self.email = email
        self.twitterUsername = twitterUsername
        self.flattrID = flattrID
        
        if chatServer != "" && chatChannel != "" {
            self.chatUrl = NSURL(string: "irc://\(chatServer)/\(chatChannel)")
            self.webchatUrl = NSURL(string: webchatUrl)
        }
        
        super.init()
        
        if let url = NSURL(string: url) {
            self.url = url
        } else {
            return nil
        }
        if let imageurl = NSURL(string: imageurl) {
            self.imageurl = imageurl
        } else {
            return nil
        }
        if let feedurl = NSURL(string: feedurl) {
            self.feedurl = feedurl
        } else {
            return nil
        }
    }
    
    // do not forget to enable them in Info.plist
    static private let subscribeURLSchemes = ["Castro" : "castro://subscribe/", "Downcast" : "downcast://", "Instacast" : "instacast://", "Overcast" : "overcast://x-callback-url/add?url=", "PocketCasts" : "pktc://subscribe/", "Podcasts" : "pcast://", "Podcat" : "podcat://"]
    
}