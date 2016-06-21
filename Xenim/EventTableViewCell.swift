//
//  EventTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import KDEAudioPlayer

class EventCellStatus {
    static let sharedInstance = EventCellStatus()
    var showsDate = true {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("toggleDateView", object: nil, userInfo: nil)
        }
    }
}

class EventTableViewCell: UITableViewCell {
    
    var playerDelegate: PlayerDelegate?
    
    @IBOutlet weak var eventCoverartImage: UIImageView! {
        didSet {
            eventCoverartImage.layer.cornerRadius = eventCoverartImage.frame.width / 2
            eventCoverartImage.layer.masksToBounds = true
            eventCoverartImage.layer.borderColor =  UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
            eventCoverartImage.layer.borderWidth = 0.5
        }
    }

    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var dateTopLabel: UILabel!
    @IBOutlet weak var dateBottomLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedDateView(_:)))
        tap.delegate = self
        dateStackView.addGestureRecognizer(tap)
        
        dateStackView.isAccessibilityElement = true
        dateStackView.accessibilityTraits = UIAccessibilityTraitButton
        dateStackView.accessibilityHint = NSLocalizedString("voiceover_dateStackView_hint", value: "Double Tap to toggle date display or days left display.", comment: "")
        dateStackView.accessibilityLabel = NSLocalizedString("voiceover_dateStackView_label", value: "event date", comment: "")
        dateBottomLabel.isAccessibilityElement = false
        dateTopLabel.isAccessibilityElement = false
        
        playButton.accessibilityLabel = NSLocalizedString("voiceover_play_button_label", value: "play button", comment: "")
        
        self.accessibilityTraits = UIAccessibilityTraitButton
    }
    
    func tappedDateView(sender: UITapGestureRecognizer?) {
        EventCellStatus.sharedInstance.showsDate = !EventCellStatus.sharedInstance.showsDate
    }
    
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
            updateFavoriteButton()
            
            playButton.hidden = !event.isLive()
            dateStackView.hidden = event.isLive()
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
            let bottomLabelString: String
            let topLabelString: String
            let accessibilityValue: String
            (topLabelString, bottomLabelString, accessibilityValue) = DateViewGenerator.generateLabelsFromDate(event.begin, showsDate: EventCellStatus.sharedInstance.showsDate)
            
            dateTopLabel.text = topLabelString
            dateBottomLabel.text = bottomLabelString
            dateStackView.accessibilityValue = accessibilityValue
        }
    }
    
    func updateFavoriteButton() {
        favoriteImageView.hidden = !Favorites.isFavorite(event.podcast.id)
        self.accessibilityValue = Favorites.isFavorite(event.podcast.id) ? NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "") : ""
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
        playerDelegate?.play(event)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewCell.toggleDateView(_:)), name: "toggleDateView", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func toggleDateView(notification: NSNotification) {
        updateLivedate()
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
