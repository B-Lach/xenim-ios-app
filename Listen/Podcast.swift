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
    var chatUrl = NSURL(string: "")!
    var webchatUrl = NSURL(string: "")!
//    var contact
//        var email
//        var twitter
//    var alternates = [NSURL]()
//    var flattrid: String?
//    var payment: String?
//    var recension: String?

    
    init?(name: String, subtitle: String, url: String, feedurl: String, imageurl: String, slug: String, podcastDescription: String, chatServer: String, chatChannel: String, webchatUrl: String) {
        self.name = name
        self.subtitle = subtitle
        self.slug = slug
        self.podcastDescription = podcastDescription
        
        super.init()
        
        if let chatUrl = NSURL(string: "irc://\(chatServer)/\(chatChannel)") {
            self.chatUrl = chatUrl
        } else {
            return nil
        }
        if let webchatUrl = NSURL(string: webchatUrl) {
            self.webchatUrl = webchatUrl
        } else {
            return nil
        }
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