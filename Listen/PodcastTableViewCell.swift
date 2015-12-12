//
//  PodcastTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {

    var podcast: Podcast? {
        didSet {
            let placeholderImage = UIImage(named: "event_placeholder")
            if let url = podcast?.imageurl {
                coverartImageView.af_setImageWithURL(url, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = placeholderImage
            }
            descriptionLabel?.text = podcast?.podcastDescription
        }
    }
    
    /**
     podcastName and podcastSlug have to be set in prepareForSegue
     the complete podcast data will then be fetched and displayed async
    */
    var podcastName: String! {
        didSet {
            podcastNameLabel?.text = podcastName
        }
    }
    var podcastSlug: String! {
        didSet {
            setupNotifications()
            coverartImageView.image = UIImage(named: "event_placeholder")
            descriptionLabel.text = ""
            updateFavoriteButton()
            HoersuppeAPI.fetchPodcastDetail(podcastSlug) { (podcast) -> Void in
                if let podcast = podcast {
                    // check if the returned data still matches the cell
                    if podcast.slug == self.podcastSlug {
                        self.podcast = podcast
                    }
                }
            }
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
    
    func updateFavoriteButton() {
        favoriteButton?.layer.cornerRadius = 5
        favoriteButton?.layer.borderWidth = 1
        favoriteButton?.layer.borderColor = Constants.Colors.tintColor.CGColor
        favoriteButton?.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        if !Favorites.fetch().contains(podcastSlug) {
            favoriteButton?.setTitleColor(Constants.Colors.tintColor, forState: .Normal)
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star"), forState: .Normal)
            favoriteButton?.backgroundColor = UIColor.whiteColor()
        } else {
            favoriteButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            favoriteButton?.setImage(UIImage(named: "white-25-star"), forState: .Normal)
            favoriteButton?.backgroundColor = Constants.Colors.tintColor
        }
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(slug: podcastSlug)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
