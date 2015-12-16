//
//  PodcastCollectionViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 06/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteCollectionViewCell: UICollectionViewCell {
    
    var podcastId: String! {
        didSet {
            updateUI()
        }
    }
    var podcast: Podcast?
    
    @IBOutlet weak var coverartImageView: UIImageView!
    
    func updateUI() {
        // check if we have detailed podcast data that still matches our cells podcast slug
        if podcast != nil && podcast!.id == podcastId {
            if let imageurl = podcast!.artwork.thumb150Url {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"), imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = UIImage(named: "event_placeholder")
            }
        } else {
            // if there is no data, fetch from API
            XenimAPI.fetchPodcastById(podcastId, onComplete: { (podcast) -> Void in
                if let podcast = podcast {
                    // check if the request that came back still matches the cell
                    if podcast.id == self.podcastId {
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
