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

    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButtonHeightConstraint: NSLayoutConstraint!
    
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
        
        if event.isLive() || event.isUpcomingToday() || event.isUpcomingTomorrow() {
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        } else if event.isUpcomingThisWeek() {
            formatter.setLocalizedDateFormatFromTemplate("EEEE HH:mm")
        } else {
            formatter.setLocalizedDateFormatFromTemplate("EEE dd.MM HH:mm")
        }
        
        dateLabel?.text = formatter.stringFromDate(event.begin)
        
        updateFavoriteButton()
        updatePlayButton()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        // scale the popover
        view.layer.cornerRadius = 5.0
        view.bounds = CGRectMake(0, 0, screenSize.width * 0.9, 400)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(event.podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star-o"), forState: .Normal)
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
        }
    }
    
    // MARK: Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: event.podcast.id)
    }
    
    @IBAction func playEvent(sender: AnyObject) {
        PlayerManager.sharedInstance.play(event)
        //TODO dismiss
    }
    
    @IBAction func moreActions(sender: AnyObject) {
        // TODO
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavoriteButton()
    }

}
