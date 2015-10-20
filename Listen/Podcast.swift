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
    
    var alternates = [String]()
    var feedurl: String
    var chat_channel: String?
    var chat_server: String?
    var chat_url: String?
//    var contact
//        var email
//        var twitter
    var description: String
    var flattrid: String?
    var imageurl: String
    var payment: String?
    var recension: String?
    var slug: String
    var subtitle: String
    var name: String // title
    var url: String
    
    init(name: String, subtitle: String, url: String, feedurl: String, imageurl: String, slug: String, description: String) {
        self.name = name
        self.subtitle = subtitle
        self.url = url
        self.feedurl = feedurl
        self.imageurl = imageurl
        self.slug = slug
        self.description = description
    }
}