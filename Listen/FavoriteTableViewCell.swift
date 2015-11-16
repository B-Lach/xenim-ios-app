//
//  FavoriteTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 27/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    var podcastSlug: String! {
        didSet {
            updateUI()
        }
    }
    var podcast: Podcast?

    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!
    
    func updateUI() {
        if podcast != nil && podcast!.slug == podcastSlug {
            podcastNameLabel.text = podcast!.name
            coverartImageView.hnk_setImageFromURL(podcast!.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        } else {
            // fetch from API
            podcastNameLabel?.text = podcastSlug
            HoersuppeAPI.fetchPodcastDetail(podcastSlug, onComplete: { (podcast) -> Void in
                if let podcast = podcast {
                    // check if the request that came back still matches the cell
                    if podcast.slug == self.podcastSlug {
                        self.podcast = podcast
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.updateUI()
                        })
                    }
                }
            })
        }
    }
}