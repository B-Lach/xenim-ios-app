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
    
    var event: Event? {
        didSet {
            if event != nil {
                podcastNameLabel.text = event?.title
                
                var formatter = NSDateFormatter();
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ";
                let defaultTimeZoneStr = formatter.stringFromDate((event?.livedate)!);
                // "2014-07-23 11:01:35 -0700" <-- same date, local, but with seconds
                formatter.timeZone = NSTimeZone(abbreviation: "UTC");
                let utcTimeZoneStr = formatter.stringFromDate((event?.livedate)!);
                
                liveDateLabel.text = defaultTimeZoneStr
                let placeholderImage = UIImage(named: "event_placeholder")!
                eventCoverartImage.image = placeholderImage
                
                // fetch info about the podcast itself
                HoersuppeAPI.fetchPodcastDetail(event!.podcastName, onComplete: { (podcast) -> Void in
                    if podcast != nil && self.event!.podcastName == podcast!.slug {
                        self.event!.podcast = podcast
                        if let URL = NSURL(string: (podcast?.imageurl)!) {
                            self.eventCoverartImage.af_setImageWithURL(URL, placeholderImage: placeholderImage)
                        }
                    }
                })
            }
        }
    }
    
}
