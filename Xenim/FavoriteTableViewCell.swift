//
//  FavoriteTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    var podcast: Podcast! {
        didSet {
            let placeholderImage = UIImage(named: "event_placeholder")!
            if let imageurl = podcast.artwork.thumb180Url{
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = placeholderImage
            }
            
            podcastNameLabel.text = podcast.name
            nextDateLabel.text = "Next Date"
        }
    }

    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var nextDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
