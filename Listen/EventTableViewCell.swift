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
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
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
            updateFavoriteButton()
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
            
            playButton?.layer.cornerRadius = 5
            playButton?.layer.borderWidth = 1
            playButton?.layer.borderColor = Constants.Colors.tintColor.CGColor
            playButton?.contentEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0)
            
            // only show the playbutton if the event is live
            if event.isLive() {
                playButton?.hidden = false
                // configure the play button image accordingly to the player state
                let playerManager = PlayerManager.sharedInstance
                if let playerEvent = playerManager.event, let myEvent = self.event {
                    if playerEvent.equals(myEvent) {
                        switch playerManager.player.state {
                        case .Buffering:
                            updatePlayButtonForBuffering()
                        case .Paused:
                            updatePlayButtonForPlay()
                        case .Playing:
                            updatePlayButtonForPause()
                        case .Stopped:
                            updatePlayButtonForPlay()
                        case .WaitingForConnection:
                            updatePlayButtonForBuffering()
                        case .Failed(_):
                            updatePlayButtonForPlay()
                        }
                    } else {
                        updatePlayButtonForPlay()
                    }
                } else {
                    updatePlayButtonForPlay()
                }
            } else {
                playButton?.hidden = true
            }
        }
    }
    
    func updatePlayButtonForBuffering() {
        playButton?.setTitle("Listen", forState: .Normal)
        playButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        playButton?.setImage(UIImage(named: "white-20-hourglass"), forState: .Normal)
        playButton?.backgroundColor = Constants.Colors.tintColor
    }
    
    func updatePlayButtonForPlay() {
        playButton?.setTitle("Listen", forState: .Normal)
        playButton?.setTitleColor(Constants.Colors.tintColor, forState: .Normal)
        playButton?.setImage(UIImage(named: "scarlet-20-play"), forState: .Normal)
        playButton?.backgroundColor = UIColor.clearColor()
    }
    
    func updatePlayButtonForPause() {
        playButton?.setTitle("Pause", forState: .Normal)
        playButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        playButton?.setImage(UIImage(named: "white-20-pause"), forState: .Normal)
        playButton?.backgroundColor = Constants.Colors.tintColor
    }
    
    func updateFavoriteButton() {
        if let event = event {
            favoriteButton?.layer.cornerRadius = 5
            favoriteButton?.layer.borderWidth = 1
            favoriteButton?.layer.borderColor = Constants.Colors.tintColor.CGColor
            favoriteButton?.contentEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0)
            
            if !Favorites.fetch().contains(event.podcastSlug) {
                favoriteButton?.setTitleColor(Constants.Colors.tintColor, forState: .Normal)
                favoriteButton?.setImage(UIImage(named: "scarlet-20-star"), forState: .Normal)
                favoriteButton?.backgroundColor = UIColor.clearColor()
            } else {
                favoriteButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                favoriteButton?.setImage(UIImage(named: "white-20-star"), forState: .Normal)
                favoriteButton?.backgroundColor = Constants.Colors.tintColor
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
    
    
    // MARK: - Actions
    
    @IBAction func favorite(sender: UIButton) {
        if let event = event {
            Favorites.toggle(slug: event.podcastSlug)
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
        updateFavoriteButton()
    }
    
}
