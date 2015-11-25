//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var podcast: Podcast? {
        didSet {
            interactionTableViewController?.podcast = podcast
        }
    }
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
    var interactionTableViewController: PodcastInteractTableViewController?
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
        
        let event = upcomingEvents[indexPath.row]
        let eventDate = event.livedate
        
        // format livedate
        let formatter = NSDateFormatter();
        formatter.locale = NSLocale.currentLocale()
        formatter.setLocalizedDateFormatFromTemplate("EEEE dd.MM HH:mm")
        
        // calculate in how many days this event takes place
        let cal = NSCalendar.currentCalendar()
        let today = cal.startOfDayForDate(NSDate())
        let diff = cal.components(NSCalendarUnit.Day,
            fromDate: today,
            toDate: eventDate,
            options: NSCalendarOptions.WrapComponents )

        // setup cell
        cell.textLabel?.text = formatter.stringFromDate(eventDate)
        if event.isToday() {
            cell.detailTextLabel?.text = NSLocalizedString("Today", value: "Today", comment: "Today").lowercaseString
        } else {
            let diffDaysString = String(format: NSLocalizedString("podcast_detailview_diff_date_string", value: "in %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), diff.day)
            cell.detailTextLabel?.text = diffDaysString
        }
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embed_tableview" {
            if let tableViewController = segue.destinationViewController as? PodcastInteractTableViewController {
                interactionTableViewController = tableViewController
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
