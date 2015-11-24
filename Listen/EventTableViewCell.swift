//
//  EventTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCoverartImage: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var liveDateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var favoriteStarImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var delegate: PlayerDelegator?
    
    var event: Event? {
        didSet {
            // notifications have to be updated every time a new event is set to this cell
            // as one notifications is based on the event this cell represents
            setupNotifications()
            updateUI()
        }
    }
    
    func updateUI() {
        if let event = event {
            podcastNameLabel?.text = event.title
            descriptionLabel?.text = event.podcastDescription
            
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
            eventCoverartImage.af_setImageWithURL(event.imageurl, placeholderImage: placeholderImage)
            
            updateProgressBar()
            updatePlayButton()
        }
    }
    
    func updatePlayButton() {
        let player = Player.sharedInstance
        if let playerEvent = player.event, let myEvent = self.event {
            if playerEvent.equals(myEvent) && player.isPlaying {
                playButton?.setImage(UIImage(named: "brandeis-blue-25-pause"), forState: .Normal)
            } else {
                playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
            }
        } else {
            playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
        }
    }
    
    func updateFavstar() {
        if let event = event {
            if !Favorites.fetch().contains(event.podcastSlug) {
                favoriteStarImageView.hidden = true
            } else {
                favoriteStarImageView.hidden = false
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
