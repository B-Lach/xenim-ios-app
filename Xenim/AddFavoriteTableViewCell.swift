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
            updateFavoriteButton()
            descriptionLabel?.text = podcast?.podcastDescription
            podcastNameLabel?.text = podcast.name
        }
    }
    
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func updateFavoriteButton() {
        if !Favorites.fetch().contains(podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
        }
    }
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavoriteButton()
    }

}
