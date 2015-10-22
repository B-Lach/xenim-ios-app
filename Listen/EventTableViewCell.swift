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
                
                let formatter = NSDateFormatter();
                formatter.locale = NSLocale.currentLocale()
                formatter.timeStyle = .FullStyle
                liveDateLabel.text = formatter.stringFromDate((self.event!.livedate!)) // todo
                
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
