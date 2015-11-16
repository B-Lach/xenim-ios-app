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
    @IBOutlet weak var coverartFavoriteStar: UILabel!
    
    var delegate: PlayerDelegator?
    
    var event: Event? {
        didSet {
            // notifications have to be updated every time a new event is set to this cell
            // as one notifications is based on the event this cell represents
            setupNotifications()
            updateUI()
        }
    }
    
    func updatePlayButton() {
        let player = Player.sharedInstance
        if let playerEvent = player.event, let myEvent = self.event {
            if playerEvent.equals(myEvent) && player.isPlaying {
                playButton?.setImage(UIImage(named: "pause"), forState: .Normal)
            } else {
                playButton?.setImage(UIImage(named: "play"), forState: .Normal)
            }
        } else {
            playButton?.setImage(UIImage(named: "play"), forState: .Normal)
        }
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
            } else if event.isThisWeek() {
                // TODO: customize this style
                formatter.dateStyle = .MediumStyle
                formatter.timeStyle = .ShortStyle
            }else {
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

            updateFavstar()
            
            let placeholderImage = UIImage(named: "event_placeholder")!
            eventCoverartImage.hnk_setImageFromURL(event.imageurl, placeholder: placeholderImage, format: nil, failure: nil, success: nil)
            
            updateProgressBar()
            updatePlayButton()
            
            playButton.hidden = false
        }
    }
    
    func updateFavstar() {
        if let event = event {
            if !Favorites.fetch().contains(event.podcastSlug) {
                coverartFavoriteStar.hidden = true
            } else {
                coverartFavoriteStar.hidden = false
            }
        }
    }
    
    func updateProgressBar() {
        if let event = event {
            progressView?.setProgress(event.progress, animated: true)
        }
    }
    
    @IBAction func play(sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.togglePlayPause(event: event!)
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("progressUpdate:"), name: "progressUpdate", object: event)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerRateChanged:"), name: "playerRateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func progressUpdate(notification: NSNotification) {
        updateProgressBar()
    }
    
    func playerRateChanged(notification: NSNotification) {
        updatePlayButton()
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavstar()
    }
    
}
