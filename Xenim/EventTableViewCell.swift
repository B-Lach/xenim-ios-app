//
//  EventTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import KDEAudioPlayer

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventCoverartImage: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var event: Event! {
        didSet {
            // notifications have to be updated every time a new event is set to this cell
            // as one notifications is based on the event this cell represents
            setupNotifications()
            updateUI()
        }
    }
    
    func updateUI() {
        if let event = event {
            podcastNameLabel?.text = event.podcast.name
            eventDescriptionLabel?.text = event.eventDescription
            eventTitleLabel?.text = event.title

            updateCoverart()
            updateLivedate()
            updatePlayButton()
            updateFavoriteButton()
        }
    }
    
    func updateCoverart() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.thumb180Url{
            eventCoverartImage.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            eventCoverartImage.image = placeholderImage
        }
    }
    
    func updateLivedate() {
        if let event = event {
            // display livedate differently according to how far in the future
            // the event is taking place
            let formatter = NSDateFormatter();
            formatter.locale = NSLocale.currentLocale()
            
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
            let time = formatter.stringFromDate(event.begin)
            dateLabel.textColor = UIColor.grayColor()
            
            if event.isLive() {
                dateLabel?.text = NSLocalizedString("live_now", value: "Live Now", comment: "live now string")
                dateLabel.textColor = Constants.Colors.tintColor
            }
            else if event.isUpcomingToday() || event.isUpcomingTomorrow() {
                dateLabel?.text = time
            } else if event.isUpcomingThisWeek() {
                formatter.setLocalizedDateFormatFromTemplate("EEEE")
                let date = formatter.stringFromDate(event.begin)
                dateLabel?.text = "\(date)\n\(time)"
            } else {
                formatter.setLocalizedDateFormatFromTemplate("EEE dd.MM")
                let date = formatter.stringFromDate(event.begin)
                dateLabel?.text = "\(date)\n\(time)"
            }
        }
    }
    
    func updatePlayButton() {
        playButton.hidden = !event.isLive()
    }
    
    func updateFavoriteButton() {
        favoriteImageView.hidden = !Favorites.fetch().contains(event.podcast.id)
    }
    
    
    // MARK: - Actions
    
    @IBAction func play(sender: AnyObject) {
        PlayerManager.sharedInstance.play(event)
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
