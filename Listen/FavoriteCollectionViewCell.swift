//
//  PodcastCollectionViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 06/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteCollectionViewCell: UICollectionViewCell {
    
    var podcastSlug: String! {
        didSet {
            updateUI()
        }
    }
    var podcast: Podcast?
    
    @IBOutlet weak var coverartImageView: UIImageView!
    
    func updateUI() {
        // check if we have detailed podcast data that still matches our cells podcast slug
        if podcast != nil && podcast!.slug == podcastSlug {
            if let imageurl = podcast!.imageurl {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"), imageTransition: .CrossDissolve(0.2))
            }
        } else {
            // if there is no data, fetch from API
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
