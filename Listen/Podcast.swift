//
//  Podcast.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import UIKit

class Podcast {
    
    var feedurl = NSURL(string: "")!
    var imageurl = NSURL(string: "")!
    var slug: String
    var subtitle: String
    var name: String // title
    var description: String
    var url = NSURL(string: "")!
//    var chat_channel: String?
//    var chat_server: String?
//    var chat_url: String?
//    var contact
//        var email
//        var twitter
//    var alternates = [NSURL]()
//    var flattrid: String?
//    var payment: String?
//    var recension: String?

    
    init?(name: String, subtitle: String, url: String, feedurl: String, imageurl: String, slug: String, description: String) {
        self.name = name
        self.subtitle = subtitle
        self.slug = slug
        self.description = description
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
    static let subscribeURLSchemes = ["Castro" : "castro://subscribe/", "Downcast" : "downcast://", "Instacast" : "instacast://", "Overcast" : "overcast://x-callback-url/add?url=", "PocketCasts" : "pktc://subscribe/", "Podcasts" : "pcast://", "Podcat" : "podcat://"]
    
}