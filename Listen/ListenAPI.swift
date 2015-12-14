//
//  ListenAPI.swift
//  Listen
//
//  Created by Stefan Trauth on 14/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

protocol ListenAPI {
    static func fetchEventById(eventId: String, onComplete: (event: Event?) -> Void)
    static func fetchScheduledEvents(maxCount maxCount: Int?, startDate: NSDate?, endDate: NSDate?, onComplete: (event: [Event]) -> Void)
    static func fetchLiveEvents(onComplete: (event: [Event]) -> Void)
    static func fetchPodcastById(podcastId: String, onComplete: (podcast: Podcast?) -> Void)
    static func fetchPodcastScheduledEvents(podcastId: String, maxCount: Int?, startDate: NSDate?, onComplete: (event: [Event]) -> Void)
    static func fetchAllPodcasts(onComplete: (podcasts: [Podcast]) -> Void)
    
}