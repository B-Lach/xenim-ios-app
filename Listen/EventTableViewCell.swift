//
//  EventTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import Haneke

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCoverartImage: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var liveDateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    var delegate: CellDelegator?
    
    var event: Event? {
        didSet {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("progressUpdate:"), name: "progressUpdate", object: event)
            updateUI()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func progressUpdate(notification: NSNotification) {
        updateProgressBar()
    }
    
    func updateUI() {
        if let event = event {
            podcastNameLabel?.text = event.title
            
            // display livedate differently according to how far in the future
            // the event is taking place
            let formatter = NSDateFormatter();
            formatter.locale = NSLocale.currentLocale()
            
            if event.isToday() || event.isTomorrow() {
                formatter.dateStyle = .NoStyle
                formatter.timeStyle = .ShortStyle
            } else {
                formatter.dateStyle = .MediumStyle
                formatter.timeStyle = .ShortStyle
            }
            
            if event.isLive() {
                playButton?.hidden = false
                progressView.hidden = false
                liveDateLabel?.text = "since \(formatter.stringFromDate(event.livedate))"
            } else {
                playButton?.hidden = true
                progressView.hidden = true
                liveDateLabel?.text = formatter.stringFromDate(event.livedate)
            }
            
            let placeholderImage = UIImage(named: "event_placeholder")!
            eventCoverartImage.hnk_setImageFromURL(event.imageurl, placeholder: placeholderImage, format: nil, failure: nil, success: nil)
            
            updateProgressBar()
            
            // show elements for DEBUGGIN
            playButton.hidden = false
            progressView.hidden = false
        }
    }
    
    func updateProgressBar() {
        if let event = event {
            print("update progress of \(event.podcastSlug)")
            progressView?.setProgress(event.progress, animated: true)
        }
    }
    
    @IBAction func play(sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.callSegueFromCell(cell: self)
        }
    }
    
}
