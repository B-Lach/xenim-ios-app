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
    
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var playButtonEffectView: UIVisualEffectView!
    
    override func viewDidLoad() {
        updateUI()
    }
    
    func updateUI() {
        self.coverartImageView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        podcastNameLabel?.text = event.title
        podcastDescriptionLabel?.text = event.description
        self.title = event.title
        
        playButtonEffectView.layer.cornerRadius = playButtonEffectView.frame.size.width/2
        playButtonEffectView.layer.masksToBounds = true

        if !event.isLive() {
            playButtonEffectView.hidden = true
        }
        
        HoersuppeAPI.fetchPodcastDetail(event.podcastSlug, onComplete: { (podcast) -> Void in
            if podcast != nil {
                self.podcast = podcast
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    //self.updateUI()
                })
            }
        })
    }
}
