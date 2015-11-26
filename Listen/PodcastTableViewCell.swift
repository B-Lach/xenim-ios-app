//
//  PodcastTableViewCell.swift
//  Listen
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {

    var podcast: Podcast?
    var podcastName: String!
    var podcastSlug: String! {
        didSet {
            podcastNameLabel?.text = podcastSlug
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
