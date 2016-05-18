//
//  FavoriteTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.size.height / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
            coverartImageView.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!

    @IBOutlet weak var nextDateStackView: UIStackView!
    @IBOutlet weak var nextDateTopLabel: UILabel!
    @IBOutlet weak var nextDateBottomLabel: UILabel!
    
    var podcast: Podcast! {
        didSet {
            let placeholderImage = UIImage(named: "event_placeholder")!
            if let imageurl = podcast.artwork.thumb180Url{
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = placeholderImage
            }
            podcastNameLabel.text = podcast.name
            nextDateTopLabel.text = ""
            nextDateBottomLabel.text = ""
            nextEvent = nil
            updateNextDate()
        }
    }
    var nextEvent: Event?
    
    var nextDateShowsDate = false;
    
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
        
    }
    
    func tappedDateView(sender: UITapGestureRecognizer?) {
        nextDateShowsDate = !nextDateShowsDate
        NSNotificationCenter.defaultCenter().postNotificationName("toggleNextDateView", object: nil, userInfo: ["nextDateShowsDate": nextDateShowsDate])
    }
    
    @objc func updateNextDate() {
        XenimAPI.fetchEvents(podcastId: podcast.id, status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in
            if let event = events.first {
                dispatch_async(dispatch_get_main_queue(), {
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
            (topLabelString, bottomLabelString, accessibilityValue) = DateViewGenerator.generateLabelsFromDate(event.begin, showsDate: nextDateShowsDate)
                
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateNextDate), name: "updateNextDate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleDateView(_:)), name: "toggleNextDateView", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func toggleDateView(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let state = userInfo["nextDateShowsDate"] as? Bool {
                nextDateShowsDate = state
                updateNextDateLabel()
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
