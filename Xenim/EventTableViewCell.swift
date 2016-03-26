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
    
    @IBOutlet weak var eventCoverartImage: UIImageView! {
        didSet {
            eventCoverartImage.layer.cornerRadius = eventCoverartImage.frame.width / 2
            eventCoverartImage.layer.masksToBounds = true
            eventCoverartImage.layer.borderColor =  UIColor.lightGrayColor().CGColor
            eventCoverartImage.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playButtonWidthConstraint: NSLayoutConstraint!
    
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
                dateLabel?.text = "\(date) \(time)"
            } else {
                formatter.setLocalizedDateFormatFromTemplate("EEE dd.MM")
                let date = formatter.stringFromDate(event.begin)
                dateLabel?.text = "\(date) \(time)"
            }
        }
    }
    
    func updatePlayButton() {
        if !event.isLive() {
            hidePlayButton()
        } else {
            showPlayButton()
            let playerManager = PlayerManager.sharedInstance
            if let playerEvent = playerManager.event {
                if playerEvent.equals(event) {
                    switch playerManager.player.state {
                    case .Buffering:
                        playButton.setImage(UIImage(named: "Pause"), forState: .Normal)
                    case .Paused:
                        playButton.setImage(UIImage(named: "Play"), forState: .Normal)
                    case .Playing:
                        playButton.setImage(UIImage(named: "Pause"), forState: .Normal)
                    case .Stopped:
                        playButton.setImage(UIImage(named: "Play"), forState: .Normal)
                    case .WaitingForConnection:
                        playButton.setImage(UIImage(named: "Pause"), forState: .Normal)
                    case .Failed(_):
                        playButton.setImage(UIImage(named: "Play"), forState: .Normal)
                    }
                } else {
                    playButton.setImage(UIImage(named: "Play"), forState: .Normal)
                }
            } else {
                playButton.setImage(UIImage(named: "Play"), forState: .Normal)
            }
        }
    }
    
    private func hidePlayButton() {
        playButtonWidthConstraint.constant = 0
    }
    
    private func showPlayButton() {
        playButtonWidthConstraint.constant = 30
    }
    
    func updateFavoriteButton() {
        favoriteImageView.hidden = !Favorites.isFavorite(event.podcast.id)
    }
    
    
    // MARK: - Actions
    
    @IBAction func play(sender: AnyObject) {
        playButton.transform = CGAffineTransformMakeScale(1.8, 1.8)
        UIView.animateWithDuration(0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.playButton.transform = CGAffineTransformIdentity
            }, completion: nil)
        PlayerManager.sharedInstance.togglePlayPause(event)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.playerStateChanged(_:)), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
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
                favoriteImageView?.hidden = false
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteImageView?.hidden = true
                animateFavoriteButton()
            }
        }
    }
    
    func animateFavoriteButton() {
        favoriteImageView.transform = CGAffineTransformMakeScale(1.3, 1.3)
        UIView.animateWithDuration(0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.favoriteImageView.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
}
