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
            coverartImageView.image = UIImage(named: "event_placeholder")
            HoersuppeAPI.fetchPodcastDetail(podcastSlug) { (podcast) -> Void in
                if let podcast = podcast {
                    if podcast.slug == self.podcastSlug {
                        self.podcast = podcast
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!
    
    
    @IBAction func addButtonPressed(sender: AnyObject) {
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
