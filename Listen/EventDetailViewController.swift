//
//  PodcastDetailViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 22/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {
    
    var podcast: Podcast?
    var event: Event!
    var podcastSlug: String!
    
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionTextView: UITextView!
    
    override func viewDidLoad() {
        updateUI()
    }
    
    func updateUI() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        coverartImageView?.image = placeholderImage
        
        if let podcast = podcast {
            // if we already have all podcast data, show it
            
            podcastNameLabel?.text = podcast.name
            podcastDescriptionTextView?.text = podcast.description
            self.title = podcast.name
            
            self.coverartImageView?.hnk_setImageFromURL(podcast.imageurl, placeholder: placeholderImage, format: nil, failure: nil, success: nil)
            
        } else {
            // if we only have the podcast slug, request all other data from the API
            HoersuppeAPI.fetchPodcastDetail(podcastSlug, onComplete: { (podcast) -> Void in
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
