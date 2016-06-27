//
//  EventTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventCellStatus {
    static let sharedInstance = EventCellStatus()
    var showsDate = true {
        didSet {
            NotificationCenter.default().post(name: Notification.Name(rawValue: "toggleDateView"), object: nil, userInfo: nil)
        }
    }
}

class EventTableViewCell: UITableViewCell {
    
    var playerDelegate: PlayerDelegate?
    
    @IBOutlet weak var eventCoverartImage: UIImageView!

    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var favoriteImageView: UIImageView! {
        didSet {
            // bugfix workaround. without this the image does not render as template
            let tint = favoriteImageView.tintColor
            favoriteImageView.tintColor = nil
            favoriteImageView.tintColor = tint
        }
    }
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
        
        eventCoverartImage.layer.cornerRadius = 4
        eventCoverartImage.layer.masksToBounds = true
        eventCoverartImage.layer.borderColor =  UIColor.lightGray().withAlphaComponent(0.3).cgColor
        eventCoverartImage.layer.borderWidth = 0.5
    }
    
    func tappedDateView(_ sender: UITapGestureRecognizer?) {
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
            
            playButton.isHidden = !event.isLive()
            dateStackView.isHidden = event.isLive()
        }
    }
    
    func updateCoverart() {
        if let imageurl = event.podcast.artwork.thumb180Url {
            eventCoverartImage.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .CrossDissolve(0.2))
        } else {
            eventCoverartImage.image = nil
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
        favoriteImageView.isHidden = !Favorites.isFavorite(event.podcast.id)
        self.accessibilityValue = Favorites.isFavorite(event.podcast.id) ? NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "") : ""
    }
    
    
    // MARK: - Actions
    
    @IBAction func play(_ sender: AnyObject) {
        playButton.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
        UIView.animate(withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.curveEaseOut],
            animations: {
                self.playButton.transform = CGAffineTransform.identity
            }, completion: nil)
        playerDelegate?.play(event)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NotificationCenter.default().removeObserver(self)
        NotificationCenter.default().addObserver(self, selector: #selector(EventTableViewCell.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(EventTableViewCell.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(EventTableViewCell.toggleDateView(_:)), name: "toggleDateView", object: nil)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    func toggleDateView(_ notification: Notification) {
        updateLivedate()
    }
    
    func favoriteAdded(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteImageView?.isHidden = false
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteImageView?.isHidden = true
                animateFavoriteButton()
            }
        }
    }
    
    func animateFavoriteButton() {
        favoriteImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        UIView.animate(withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.curveEaseOut],
            animations: {
                self.favoriteImageView.transform = CGAffineTransform.identity
            }, completion: nil)
    }
    
}
