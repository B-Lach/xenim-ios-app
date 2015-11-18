//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices

class PodcastDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    var podcast: Podcast?
    var event: Event?
    var upcomingEvents = [Event]()
    
    var delegate: PlayerDelegator?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var playButtonEffectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var upcomingEventsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var upcomingEventsTableView: UITableView! {
        didSet {
            upcomingEventsTableView.delegate = self
            upcomingEventsTableView.dataSource = self
        }
    }
    
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
        
        HoersuppeAPI.fetchPodcastNextLiveEvents(podcastSlug, count: 3) { (events) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.upcomingEvents = events
                self.upcomingEventsTableView.reloadData()
    
                self.upcomingEventsHeightConstraint.constant = self.upcomingEventsTableView.contentSize.height

                self.contentView.setNeedsLayout()
            })
        }
        
        if podcast == nil {
            HoersuppeAPI.fetchPodcastDetail(podcastSlug, onComplete: { (podcast) -> Void in
                if podcast != nil {
                    self.podcast = podcast
//                  dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                      self.updateUI()
//                  })
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
            favoriteButton.setTitle("☆", forState: .Normal)
        } else {
            favoriteButton.setTitle("★", forState: .Normal)
        }
    }
    
    @IBAction func openPodcastWebsite() {
        if let podcast = podcast {
            let svc = SFSafariViewController(URL: podcast.url)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func openChat(sender: AnyObject) {
        if let chatUrl = podcast?.chatUrl, let webchatUrl = podcast?.webchatUrl {
            if UIApplication.sharedApplication().canOpenURL(chatUrl) {
                // open associated app
                UIApplication.sharedApplication().openURL(chatUrl)
            } else {
                // open webchat in safari
                UIApplication.sharedApplication().openURL(webchatUrl)
            }
        }
    }
    
    @IBAction func subscribePodcast() {
        if let podcast = self.podcast {
            let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("podcast_detailview_subscribe_alert_message", value: "Choose Podcast Client", comment: "when the user clicks on the podcast subscribe button an alert view opens to choose a podcast client. this is the message of the alert view."), preferredStyle: .ActionSheet)
            
            // create one option for each podcast client
            for client in podcast.subscribeClients {
                let clientName = client.0
                let subscribeURL = client.1
                
                // only show the option if the podcast client is installed which reacts to this URL
                if UIApplication.sharedApplication().canOpenURL(subscribeURL) {
                    let action = UIAlertAction(title: clientName, style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                        UIApplication.sharedApplication().openURL(subscribeURL)
                    })
                    optionMenu.addAction(action)
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "cancel string"), style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    @IBAction func playEvent(sender: AnyObject) {
        if let event = event {
            if let delegate = self.delegate {
                delegate.togglePlayPause(event: event)
            }
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return upcomingEvents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UpcomingEvent", forIndexPath: indexPath)
        
        let formatter = NSDateFormatter();
        formatter.locale = NSLocale.currentLocale()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle

        cell.textLabel?.text = formatter.stringFromDate(upcomingEvents[indexPath.row].livedate)
        return cell
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
