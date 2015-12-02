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
            if let url = podcast?.imageurl {
                coverartImageView.af_setImageWithURL(url, placeholderImage: UIImage(named: "event_placeholder"))
            }
        }
    }
    var podcastName: String! {
        didSet {
            podcastNameLabel?.text = podcastName
        }
    }
    var podcastSlug: String! {
        didSet {
            setupNotifications()
            coverartImageView.image = UIImage(named: "event_placeholder")
            updateFavoriteButton()
            HoersuppeAPI.fetchPodcastDetail(podcastSlug) { (podcast) -> Void in
                if let podcast = podcast {
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
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(podcastSlug) {
            favoriteButton.setImage(UIImage(named: "corn-44-star"), forState: .Normal)
        } else {
            favoriteButton.setImage(UIImage(named: "corn-44-star-o"), forState: .Normal)
        }
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(slug: podcastSlug)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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
