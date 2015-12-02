//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastDetailViewController: UIViewController {
    
    var podcast: Podcast? {
        didSet {
            // assign the podcast object to the tableview controller in the container view
            interactionTableViewController?.podcast = podcast
        }
    }
    var event: Event?
    
    var delegate: PlayerDelegator?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var playButtonEffectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    var interactionTableViewController: PodcastInteractTableViewController?
    @IBOutlet weak var favoriteButton: UIButton!
    
    override func viewDidLoad() {
        // LNPopupBarHeight is currently 40
        // increase bottom inset to show all content if player is visible
        scrollView.contentInset.bottom = scrollView.contentInset.bottom + 40
        
        setupNotifications()
        
        playButtonEffectView.layer.cornerRadius = playButtonEffectView.frame.size.width/2
        playButtonEffectView.layer.masksToBounds = true
        
        updateUI()
    }
    
    func updateUI() {
        
        var title = ""
        var description = ""
        var imageurl = NSURL()
        var podcastSlug = ""
        
        if let event = event {
            title = event.title
            description = event.podcastDescription
            imageurl = event.imageurl
            podcastSlug = event.podcastSlug
        } else if let podcast = podcast {
            title = podcast.name
            description = podcast.podcastDescription
            imageurl = podcast.imageurl
            podcastSlug = podcast.slug
        }
        
        self.coverartImageView?.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        podcastNameLabel?.text = title
        self.title = title
        podcastDescriptionLabel?.text = description

        updatePlayButton()
        updateFavoritesButton()
        
        if podcast == nil {
            HoersuppeAPI.fetchPodcastDetail(podcastSlug, onComplete: { (podcast) -> Void in
                if podcast != nil {
                    self.podcast = podcast
                }
            })
        }
    }
    
    func updatePlayButton() {
        if let event = event {
            if event.isLive() {
                playButtonEffectView.hidden = false
            }
            let player = Player.sharedInstance
            if let playerEvent = player.event {
                if playerEvent.equals(event) && player.isPlaying {
                    playButton?.setImage(UIImage(named: "pause"), forState: .Normal)
                } else {
                    playButton?.setImage(UIImage(named: "play"), forState: .Normal)
                }
            } else {
                playButton?.setImage(UIImage(named: "play"), forState: .Normal)
            }
        }

    }
    
    func updateFavoritesButton() {
        var podcastSlug = ""
        if let podcast = podcast {
            podcastSlug = podcast.slug
        } else if let event = event {
            podcastSlug = event.podcastSlug
        }
        
        if !Favorites.fetch().contains(podcastSlug) {
            favoriteButton?.setImage(UIImage(named: "corn-44-star-o"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "corn-44-star"), forState: .Normal)
        }
    }
    
    @IBAction func playEvent(sender: AnyObject) {
        if let event = event {
            if let delegate = self.delegate {
                delegate.togglePlayPause(event: event)
            }
        }
    }
    
    @IBAction func favorite(sender: UIButton) {
        var podcastSlug = ""
        if let podcast = podcast {
            podcastSlug = podcast.slug
        } else if let event = event {
            podcastSlug = event.podcastSlug
        }
        Favorites.toggle(slug: podcastSlug)
    }
    
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
    
    // MARK: notifications
    
    func setupNotifications() {
        if event != nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerRateChanged:"), name: "playerRateChanged", object: nil)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerRateChanged(notification: NSNotification) {
        updatePlayButton()
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavoritesButton()
    }
}
