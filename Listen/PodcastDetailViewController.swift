//
//  PodcastDetailViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import KDEAudioPlayer

class PodcastDetailViewController: UIViewController {
    
    /**
        This view can either be initialized via segue by setting the podcast
        or by setting the event.
        If only event is set, the podcast data will be fetched async.
        If only podcast is set, there will not be any event based display (like play button).
    */
    
    var podcast: Podcast? {
        didSet {
            // assign the podcast object to the tableview controller in the container view
            interactionTableViewController?.podcast = podcast
        }
    }
    var event: Event? {
        didSet {
            podcast = event?.podcast
        }
    }
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    var interactionTableViewController: PodcastInteractTableViewController?
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: - init
    
    override func viewDidLoad() {
        // LNPopupBarHeight is currently 40
        // increase bottom inset to show all content if player is visible
        scrollView.contentInset.bottom = scrollView.contentInset.bottom + 40
        
        setupNotifications()
        
        updateUI()
    }
    
    // MARK: - Update UI
    
    func updateUI() {
        
        let placeholderImage = UIImage(named: "event_placeholder")
        if let imageurl = podcast?.artwork.originalUrl {
            self.coverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            self.coverartImageView?.image = placeholderImage
        }
        
        podcastNameLabel?.text = event?.title != nil ? event?.title : podcast?.name
        self.title = podcast?.name
        podcastDescriptionLabel?.text = event?.eventDescription != nil ? event?.eventDescription : podcast?.podcastDescription

        updatePlayButton()
        updateFavoritesButton()
    }
    
    func updatePlayButton() {
        if let event = event {
            if event.isLive() {
                playButton.hidden = false
                
                let playerManager = PlayerManager.sharedInstance
                if let playerEvent = playerManager.event {
                    if playerEvent.equals(event) {
                        switch playerManager.player.state {
                        case .Buffering:
                            playButton.hidden = true
                        case .Paused:
                            playButton.hidden = true
                        case .Playing:
                            playButton.hidden = true
                        case .Stopped:
                            playButton?.setImage(UIImage(named: "scarlet-70-play-circle"), forState: .Normal)
                        case .WaitingForConnection:
                            playButton.hidden = true
                        case .Failed(_):
                            playButton?.setImage(UIImage(named: "scarlet-70-play-circle"), forState: .Normal)
                        }
                    } else {
                        playButton?.setImage(UIImage(named: "scarlet-70-play-circle"), forState: .Normal)
                    }
                } else {
                    playButton?.setImage(UIImage(named: "scarlet-70-play-circle"), forState: .Normal)
                }
                
            } else {
                playButton.hidden = true
            }
        } else {
            playButton.hidden = true
        }

    }
    
    func updateFavoritesButton() {
        favoriteButton?.layer.cornerRadius = 5
        favoriteButton?.layer.borderWidth = 1
        favoriteButton?.layer.borderColor = Constants.Colors.tintColor.CGColor
        favoriteButton?.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        if !Favorites.fetch().contains(podcast!.id) {
            favoriteButton?.setTitleColor(Constants.Colors.tintColor, forState: .Normal)
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star"), forState: .Normal)
            favoriteButton?.backgroundColor = UIColor.whiteColor()
        } else {
            favoriteButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            favoriteButton?.setImage(UIImage(named: "white-25-star"), forState: .Normal)
            favoriteButton?.backgroundColor = Constants.Colors.tintColor
        }
    }
    
    // MARK: - Actions
    
    @IBAction func playEvent(sender: AnyObject) {
        if let event = event {
            PlayerManager.sharedInstance.togglePlayPause(event)
        }
    }
    
    @IBAction func favorite(sender: UIButton) {
        Favorites.toggle(podcastId: podcast!.id)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embed_tableview" {
            if let tableViewController = segue.destinationViewController as? PodcastInteractTableViewController {
                interactionTableViewController = tableViewController
                if let podcast = podcast {
                    interactionTableViewController!.podcast = podcast
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    func setupNotifications() {
        if event != nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerStateChanged(notification: NSNotification) {
        updatePlayButton()
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavoritesButton()
    }
}
