//
//  ListenAPI.swift
//  Listen
//
//  Created by Stefan Trauth on 14/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

protocol ListenAPI {
    static func fetchEventById(eventId: String, onComplete: (event: Event?) -> Void)
    static func fetchUpcomingEvents(maxCount maxCount: Int?, onComplete: (events: [Event]) -> Void)
    static func fetchLiveEvents(onComplete: (events: [Event]) -> Void)
    static func fetchPodcastById(podcastId: String, onComplete: (podcast: Podcast?) -> Void)
    static func fetchPodcastUpcomingEvents(podcastId: String, maxCount: Int?, onComplete: (events: [Event]) -> Void)
    static func fetchAllPodcasts(onComplete: (podcasts: [Podcast]) -> Void)
    
}