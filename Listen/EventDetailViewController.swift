//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var podcast: Podcast?
    var event: Event!
    var upcomingEvents = [Event]()
    
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var playButtonEffectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var upcomingEventsHeightConstraint: NSLayoutConstraint!
    
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
        updateUI()
    }
    
    func updateUI() {
        self.coverartImageView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        podcastNameLabel?.text = event.title
        podcastDescriptionLabel?.text = event.description
        self.title = event.title
        
        playButtonEffectView.layer.cornerRadius = playButtonEffectView.frame.size.width/2
        playButtonEffectView.layer.masksToBounds = true

        if !event.isLive() {
            playButtonEffectView.hidden = true
        }
        
        HoersuppeAPI.fetchPodcastNextLiveEvents(event.podcastSlug, count: 3) { (events) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.upcomingEvents = events
                self.upcomingEventsTableView.reloadData()
    
                self.upcomingEventsHeightConstraint.constant = self.upcomingEventsTableView.contentSize.height

                self.contentView.setNeedsLayout()
            })
        }
        
        HoersuppeAPI.fetchPodcastDetail(event.podcastSlug, onComplete: { (podcast) -> Void in
            if podcast != nil {
                self.podcast = podcast
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    //self.updateUI()
                })
            }
        })
    }
    
    @IBAction func subscribePodcast() {
        if let podcast = self.podcast {
            let optionMenu = UIAlertController(title: nil, message: "Choose Podcast Client", preferredStyle: .ActionSheet)
            
            for client in Podcast.subscribeURLSchemes {
                let clientName = client.0
                let urlScheme = client.1
                
                if let subscribeURL = NSURL(string: urlScheme + podcast.feedurl.description) {
                    if UIApplication.sharedApplication().canOpenURL(subscribeURL) {
                        let action = UIAlertAction(title: clientName, style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                            
                            UIApplication.sharedApplication().openURL(subscribeURL)
                            
                        })
                        optionMenu.addAction(action)
                    }
                }
                
                
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                print("Cancelled")
            })
            
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
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
}
