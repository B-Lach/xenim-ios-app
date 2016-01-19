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
            
            podcast.getDaysUntilNextEvent { (days) -> Void in
                // TODO check if this is still the right cell
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if days < 0 {
                        // no event scheduled
                        let noEventString = String(format: NSLocalizedString("favorite_tableviewcell_no_event_scheduled", value: "Nothing scheduled", comment: "Tells the user that there is no event scheduled in the future"))
                        self.nextDateLabel?.text = noEventString
                    } else if days == 0 {
                        // the event is today
                        self.nextDateLabel?.text = NSLocalizedString("Today", value: "Today", comment: "Today").lowercaseString
                    } else {
                        // the event is in the future
                        let diffDaysString = String(format: NSLocalizedString("favorite_tableviewcell_diff_date_string", value: "in %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), days)
                        self.nextDateLabel?.text = diffDaysString
                    }
                })
            }
        }
    }

    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var nextDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tintColor = Constants.Colors.tintColor
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
