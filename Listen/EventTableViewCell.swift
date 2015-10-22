//
//  EventTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import AlamofireImage

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCoverartImage: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var liveDateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var event: Event? {
        didSet {
            if event != nil {
                podcastNameLabel.text = event?.title
                
                if let date = event!.livedate {
                    let calendar = NSCalendar.currentCalendar()
                    let formatter = NSDateFormatter();
                    formatter.locale = NSLocale.currentLocale()
                    
                    if calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
                        formatter.dateStyle = .NoStyle
                        formatter.timeStyle = .ShortStyle
                    } else {
                        formatter.dateStyle = .MediumStyle
                        formatter.timeStyle = .ShortStyle
                    }
                    
                    // check if live
                    let now = NSDate()
                    let eventStartDate = event!.livedate!
                    let duration: NSTimeInterval = (Double)(event!.duration * 60)
                    let eventEndDate = event!.livedate!.dateByAddingTimeInterval(duration) // event.duration is minutes
                    if eventStartDate.earlierDate(now) == eventStartDate && eventEndDate.laterDate(now) == eventEndDate {
                        playButton.hidden = false
                        liveDateLabel.text = "since \(formatter.stringFromDate(date))"
                    } else {
                        liveDateLabel.text = formatter.stringFromDate(date)
                    }
                }
                
                let placeholderImage = UIImage(named: "event_placeholder")!
                eventCoverartImage.image = placeholderImage
                
                // fetch info about the podcast itself
                HoersuppeAPI.fetchPodcastDetail(event!.podcastName, onComplete: { (podcast) -> Void in
                    if podcast != nil && self.event!.podcastName == podcast!.slug {
                        self.event!.podcast = podcast
                        
                        self.eventCoverartImage.af_setImageWithURL(NSURL(string: (podcast?.imageurl)!)!, placeholderImage: placeholderImage)
                    }
                })
            }
        }
    }
    
}
