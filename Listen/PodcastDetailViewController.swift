//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastDetailViewController: UIViewController {
    
    var podcast: Podcast?
    var podcastSlug: String!
    
    @IBOutlet weak var blurredCoverartImageView: UIImageView!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionTextView: UITextView!
    
    override func viewDidLoad() {
        updateUI()
    }
    
    func updateUI() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        coverartImageView?.image = placeholderImage
        blurredCoverartImageView?.image = placeholderImage
        
        if let podcast = podcast {
            podcastNameLabel?.text = podcast.name
            podcastDescriptionTextView?.text = podcast.description
            self.title = podcast.name
            
            self.coverartImageView?.af_setImageWithURL(podcast.imageurl, placeholderImage: placeholderImage)
            self.blurredCoverartImageView?.af_setImageWithURL(podcast.imageurl, placeholderImage: placeholderImage)
        } else if podcastSlug != nil {
            HoersuppeAPI.fetchPodcastDetail(podcastSlug!, onComplete: { (podcast) -> Void in
                if podcast != nil {
                    self.podcast = podcast
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateUI()
                    })
                }
            })
        }
    }
}
