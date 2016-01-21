//
//  EventDetailViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 15/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {
    
    var event: Event!

    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = 5.0
            coverartImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButtonHeightConstraint: NSLayoutConstraint!
    
    var dismissHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.thumb180Url{
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        
        podcastNameLabel.text = event.podcast.name
        eventTitleLabel.text = event.title
        eventDescriptionTextView.text = event.eventDescription
        
        // display livedate differently according to how far in the future
        // the event is taking place
        let formatter = NSDateFormatter();
        formatter.locale = NSLocale.currentLocale()
        
        if event.isLive() {
            dateLabel?.text = NSLocalizedString("live_now", value: "Live Now", comment: "live now string")
        } else if event.isUpcomingToday() || event.isUpcomingTomorrow() {
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
            dateLabel?.text = formatter.stringFromDate(event.begin)
        } else if event.isUpcomingThisWeek() {
            formatter.setLocalizedDateFormatFromTemplate("EEEE HH:mm")
            dateLabel?.text = formatter.stringFromDate(event.begin)
        } else {
            formatter.setLocalizedDateFormatFromTemplate("EEE dd.MM HH:mm")
            dateLabel?.text = formatter.stringFromDate(event.begin)
        }
                
        updateFavoriteButton()
        updatePlayButton()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillLayoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        // scale the popover
        view.layer.cornerRadius = 5.0
        view.bounds = CGRectMake(0, 0, screenSize.width * 0.9, 400)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(event.podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
        }
    }
    
    func updatePlayButton() {
        // general stuff
        playButton.backgroundColor = Constants.Colors.tintColor
        playButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        playButton?.layer.cornerRadius = 5
        playButton?.layer.borderWidth = 0
        playButton?.contentEdgeInsets = UIEdgeInsetsMake(10, 5, 10, 5)
        
        if !event.isLive() {
            // hide the playbutton
            playButtonHeightConstraint.constant = 0
        } else {
            let playerManager = PlayerManager.sharedInstance
            if let playerEvent = playerManager.event {
                if playerEvent.equals(event) {
                    switch playerManager.player.state {
                    case .Buffering:
                        playButtonHeightConstraint.constant = 0
                    case .Paused:
                        break
                    case .Playing:
                        playButtonHeightConstraint.constant = 0
                    case .Stopped:
                        break
                    case .WaitingForConnection:
                        playButtonHeightConstraint.constant = 0
                    case .Failed(_):
                        break
                    }
                }
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: event.podcast.id)
    }
    
    @IBAction func playEvent(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
        if dismissHandler != nil {
            dismissHandler!()
        }
    }
    
    @IBAction func moreActions(sender: AnyObject) {
        // TODO
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteAdded:"), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteRemoved:"), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerStateChanged(notification: NSNotification) {
        updatePlayButton()
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func animateFavoriteButton() {
        favoriteButton.transform = CGAffineTransformMakeScale(1.3, 1.3)
        UIView.animateWithDuration(0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.favoriteButton.transform = CGAffineTransformIdentity
            }, completion: nil)
    }

}
