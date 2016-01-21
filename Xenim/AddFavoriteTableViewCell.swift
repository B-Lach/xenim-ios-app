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
            
            if !Favorites.fetch().contains(podcast.id) {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
            } else {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
            }
            
            descriptionLabel?.text = podcast?.podcastDescription
            podcastNameLabel?.text = podcast.name
        }
    }
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = 5.0
            coverartImageView.layer.masksToBounds = true
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteAdded:"), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteRemoved:"), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
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
