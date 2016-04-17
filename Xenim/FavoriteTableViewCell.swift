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
            updateNextDate()
        }
    }
    
    @objc func updateNextDate() {
        nextDateLabel.text = NSLocalizedString("favorite_tableview_loading_next_event", value: "Loading...", comment: "Loading message while loading next event date")
    
        XenimAPI.fetchEvents(podcastId: podcast.id, status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in

            if let event = events.first {
                let dateLabelString: String
                
                if event.isLive() {
                    dateLabelString = NSLocalizedString("live_now", value: "Live Now", comment: "Live Now")
                } else if event.isUpcoming() {
                    // calculate in how many days this event takes place
                    let cal = NSCalendar.currentCalendar()
                    let today = cal.startOfDayForDate(NSDate())
                    let diff = cal.components(NSCalendarUnit.Day,
                                              fromDate: today,
                                              toDate: events.first!.begin,
                                              options: NSCalendarOptions.WrapComponents )
                    let days = diff.day
                    if days == 0 {
                        // event is today
                        dateLabelString = NSLocalizedString("Today", value: "Today", comment: "Today")
                    } else {
                        // the event is in the future
                        dateLabelString = String(format: NSLocalizedString("favorite_tableviewcell_diff_date_string", value: "In %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), days)
                    }
                } else {
                    // no upcoming events
                    dateLabelString = String(format: NSLocalizedString("favorite_tableviewcell_no_event_scheduled", value: "Nothing scheduled", comment: "Tells the user that there is no event scheduled in the future"))
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.nextDateLabel.text = dateLabelString
                })
            }
            
        }
        
    }

    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.size.height / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
            coverartImageView.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var nextDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateNextDate), name: "updateNextDate", object: nil)
        self.tintColor = Constants.Colors.tintColor
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
