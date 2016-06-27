//
//  FavoriteTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteCellStatus {
    static let sharedInstance = FavoriteCellStatus()
    var showsDate = false {
        didSet {
            NotificationCenter.default().post(name: Notification.Name(rawValue: "toggleNextDateView"), object: nil, userInfo: nil)
        }
    }
}

class FavoriteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!

    @IBOutlet weak var nextDateStackView: UIStackView!
    @IBOutlet weak var nextDateTopLabel: UILabel!
    @IBOutlet weak var nextDateBottomLabel: UILabel!
    
    var podcast: Podcast! {
        didSet {
            if let imageurl = podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = nil
            }
            podcastNameLabel.text = podcast.name
            nextDateTopLabel.text = ""
            nextDateBottomLabel.text = ""
            nextEvent = nil
            updateNextDate()
        }
    }
    var nextEvent: Event?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tintColor = Constants.Colors.tintColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedDateView(_:)))
        tap.delegate = self
        nextDateStackView.addGestureRecognizer(tap)
        setupNotifications()
        
        nextDateStackView.isAccessibilityElement = true
        nextDateStackView.accessibilityTraits = UIAccessibilityTraitButton
        nextDateStackView.accessibilityHint = NSLocalizedString("voiceover_nextDateStackView_hint", value: "Double Tap to toggle date display or days left display.", comment: "")
        nextDateStackView.accessibilityLabel = NSLocalizedString("voiceover_nextDateStackView_label", value: "next event date", comment: "")
        nextDateTopLabel.isAccessibilityElement = false
        nextDateBottomLabel.isAccessibilityElement = false
        
        self.accessibilityTraits = UIAccessibilityTraitButton
        
        coverartImageView.layer.cornerRadius = 4
        coverartImageView.layer.masksToBounds = true
        coverartImageView.layer.borderColor =  UIColor.lightGray().withAlphaComponent(0.3).cgColor
        coverartImageView.layer.borderWidth = 0.5
        
    }
    
    func tappedDateView(_ sender: UITapGestureRecognizer?) {
        FavoriteCellStatus.sharedInstance.showsDate = !FavoriteCellStatus.sharedInstance.showsDate
    }
    
    @objc func updateNextDate() {
        XenimAPI.fetchEvents(podcastId: podcast.id, status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in
            if let event = events.first {
                DispatchQueue.main.async(execute: {
                    // make sure this is still the correct cell
                    if event.podcast.id == self.podcast.id {
                        self.nextEvent = event
                    }
                    self.updateNextDateLabel()
                })
            }
        }
    }
    
    func updateNextDateLabel() {
        if let event = nextEvent {
            let bottomLabelString: String
            let topLabelString: String
            let accessibilityValue: String
            (topLabelString, bottomLabelString, accessibilityValue) = DateViewGenerator.generateLabelsFromDate(event.begin, showsDate: FavoriteCellStatus.sharedInstance.showsDate)
                
            nextDateTopLabel.text = topLabelString
            nextDateBottomLabel.text = bottomLabelString
            nextDateStackView.accessibilityValue = accessibilityValue
        } else {
            // no upcoming event
            nextDateTopLabel.text = ""
            nextDateBottomLabel.text = ""
            nextDateStackView.accessibilityValue = NSLocalizedString("voiceover_nextDateStackView_value_nothing_scheduled", value: "nothing scheduled", comment: "")
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NotificationCenter.default().removeObserver(self)
                NotificationCenter.default().addObserver(self, selector: #selector(updateNextDate), name: "updateNextDate", object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(toggleDateView(_:)), name: "toggleNextDateView", object: nil)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    func toggleDateView(_ notification: Notification) {
        updateNextDateLabel()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
