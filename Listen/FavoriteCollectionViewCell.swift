//
//  PodcastCollectionViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 06/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteCollectionViewCell: UICollectionViewCell {
    
    var podcast: Podcast? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var coverartImageView: UIImageView!
    
    func updateUI() {
        if let podcast = podcast {
            if let imageurl = podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"), imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = UIImage(named: "event_placeholder")
            }
        }
    }
    
}
