//
//  EventTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import KDEAudioPlayer

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCoverartImage: UIImageView! {
        didSet {
            eventCoverartImage.layer.cornerRadius = 5.0
            eventCoverartImage.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var liveDateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var favoriteStarImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
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
            
            let placeholderImage = UIImage(named: "event_placeholder")!
            if let imageurl = event.imageurl {
                eventCoverartImage.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                eventCoverartImage.image = placeholderImage
            }
            
            updateLivedate()
            updateProgressBar()
            updatePlayButton()
            updateFavstar()
        }
    }
    
    func updateLivedate() {
        if let event = event {
            // display livedate differently according to how far in the future
            // the event is taking place
            let formatter = NSDateFormatter();
            formatter.locale = NSLocale.currentLocale()
            
            if event.isToday() || event.isTomorrow() {
                formatter.setLocalizedDateFormatFromTemplate("HH:mm")
            } else if event.isThisWeek() {
                formatter.setLocalizedDateFormatFromTemplate("EEEE HH:mm")
            } else {
                formatter.setLocalizedDateFormatFromTemplate("EEE dd.MM HH:mm")
            }
            
            if event.isLive() {
                liveDateLabel?.text = "since \(formatter.stringFromDate(event.livedate))"
            } else {
                liveDateLabel?.text = formatter.stringFromDate(event.livedate)
            }
        }
    }
    
    func updatePlayButton() {
        if let event = event {
            // only show the playbutton if the event is live
            if event.isLive() {
                playButton?.hidden = false
                // configure the play button image accordingly to the player state
                let playerManager = PlayerManager.sharedInstance
                if let playerEvent = playerManager.event, let myEvent = self.event {
                    if playerEvent.equals(myEvent) {
                        switch playerManager.player.state {
                        case .Buffering:
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-hourglass"), forState: .Normal)
                        case .Paused:
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
                        case .Playing:
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-pause"), forState: .Normal)
                        case .Stopped:
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
                        case .WaitingForConnection:
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-hourglass"), forState: .Normal)
                        case .Failed(_):
                            playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
                        }
                    } else {
                        playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
                    }
                } else {
                    playButton?.setImage(UIImage(named: "brandeis-blue-25-play"), forState: .Normal)
                }
            } else {
                playButton?.hidden = true
            }
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
            if event.isLive() {
                progressView?.hidden = false
            } else {
                progressView?.hidden = true
            }
        }
    }
    
    @IBAction func play(sender: AnyObject) {
        if let event = event {
            PlayerManager.sharedInstance.togglePlayPause(event)
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("progressUpdate:"), name: "progressUpdate", object: event)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func progressUpdate(notification: NSNotification) {
        updateProgressBar()
    }
    
    func playerStateChanged(notification: NSNotification) {
        updatePlayButton()
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavstar()
    }
    
}
