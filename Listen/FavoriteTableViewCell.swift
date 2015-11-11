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
            podcastNameLabel?.text = podcastSlug
        }
    }

    @IBOutlet weak var podcastNameLabel: UILabel!
}
