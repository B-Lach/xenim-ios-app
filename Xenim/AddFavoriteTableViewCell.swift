//
//  PodcastTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class AddFavoriteTableViewCell: UITableViewCell {

    var podcast: Podcast! {
        didSet {
            let placeholderImage = UIImage(named: "event_placeholder")
            if let imageurl = podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = placeholderImage
            }
            setupNotifications()
            
            favoriteButton.accessibilityLabel = " "
            favoriteButton.accessibilityHint = NSLocalizedString("voiceover_favorite_button_hint", value: "double tap to toggle favorite", comment: "") 
            
            if !Favorites.isFavorite(podcast.id) {
                favoriteButton?.setImage(UIImage(named: "star_o_44"), forState: .Normal)
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            } else {
                favoriteButton?.setImage(UIImage(named: "star_44"), forState: .Normal)
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
            
            self.accessibilityTraits = UIAccessibilityTraitButton
            
            descriptionLabel?.text = podcast?.podcastDescription
            podcastNameLabel?.text = podcast.name
        }
    }
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.size.height / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
            coverartImageView.layer.borderWidth = 0.5
        }
    }

    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: podcast.id)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddFavoriteTableViewCell.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddFavoriteTableViewCell.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "star_44"), forState: .Normal)
                animateFavoriteButton()
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "star_o_44"), forState: .Normal)
                animateFavoriteButton()
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
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
