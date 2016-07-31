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
            if let imageurl = podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .crossDissolve(0.2))
            } else {
                coverartImageView.image = nil
            }
            
            setupNotifications()
            
            favoriteButton.accessibilityLabel = " "
            favoriteButton.accessibilityHint = NSLocalizedString("voiceover_favorite_button_hint", value: "double tap to toggle favorite", comment: "") 
            
            if !Favorites.isFavorite(podcast.id) {
                favoriteButton?.setImage(UIImage(named: "star_o_35"), for: UIControlState())
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            } else {
                favoriteButton?.setImage(UIImage(named: "star_35"), for: UIControlState())
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
            
            self.accessibilityTraits = UIAccessibilityTraitButton
            
            descriptionLabel?.text = podcast?.podcastDescription
            podcastNameLabel?.text = podcast.name
        }
    }
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!

    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBAction func toggleFavorite(_ sender: AnyObject) {
        Favorites.toggle(podcastId: podcast.id)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverartImageView.layer.cornerRadius = 4
        coverartImageView.layer.masksToBounds = true
        coverartImageView.layer.borderColor =  UIColor.lightGray().withAlphaComponent(0.3).cgColor
        coverartImageView.layer.borderWidth = 0.5
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(AddFavoriteTableViewCell.favoriteAdded(_:)), name: Favorites.favoriteAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddFavoriteTableViewCell.favoriteRemoved(_:)), name: Favorites.favoriteRemovedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func favoriteAdded(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "star_35"), for: UIControlState())
                animateFavoriteButton()
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "star_o_35"), for: UIControlState())
                animateFavoriteButton()
                favoriteButton.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            }
        }
    }

    func animateFavoriteButton() {
        favoriteButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        UIView.animate(withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.curveEaseOut],
            animations: {
                self.favoriteButton.transform = CGAffineTransform.identity
            }, completion: nil)
    }
    
}
