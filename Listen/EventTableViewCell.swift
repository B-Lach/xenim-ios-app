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
    
    var delegate: CellDelegator?
    
    var event: Event? {
        didSet {
            if event != nil {
                
                playButton?.hidden = false
                
                
                
                
                
                
                podcastNameLabel?.text = event?.title
                
                let formatter = NSDateFormatter();
                formatter.locale = NSLocale.currentLocale()
                
                if event!.isToday() || event!.isTomorrow() {
                    formatter.dateStyle = .NoStyle
                    formatter.timeStyle = .ShortStyle
                } else {
                    formatter.dateStyle = .MediumStyle
                    formatter.timeStyle = .ShortStyle
                }
                
                if event!.isLive() {
                    //playButton?.hidden = false
                    liveDateLabel?.text = "since \(formatter.stringFromDate(event!.livedate))"
                } else {
                    //playButton?.hidden = true
                    liveDateLabel?.text = formatter.stringFromDate(event!.livedate)
                }
                
                let placeholderImage = UIImage(named: "event_placeholder")!
                eventCoverartImage.af_setImageWithURL(NSURL(string: (event?.imageurl)!)!, placeholderImage: placeholderImage)
            }
        }
    }
    
    @IBAction func play(sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.callSegueFromCell(cell: self)
        }
    }
    
}
