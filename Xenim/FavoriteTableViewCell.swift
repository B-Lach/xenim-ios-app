//
//  FavoriteTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.size.height / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
            coverartImageView.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!

    @IBOutlet weak var nextDateStackView: UIStackView!
    @IBOutlet weak var nextDateTopLabel: UILabel!
    @IBOutlet weak var nextDateBottomLabel: UILabel!
    
    var podcast: Podcast! {
        didSet {
            let placeholderImage = UIImage(named: "event_placeholder")!
            if let imageurl = podcast.artwork.thumb180Url{
                coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            } else {
                coverartImageView.image = placeholderImage
            }
            podcastNameLabel.text = podcast.name
            nextDateTopLabel.text = ""
            nextDateBottomLabel.text = ""
            nextEvent = nil
            updateNextDate()
        }
    }
    var nextEvent: Event?
    
    var nextDateShowsDate = false;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tintColor = Constants.Colors.tintColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedDateView(_:)))
        tap.delegate = self
        nextDateStackView.addGestureRecognizer(tap)
        setupNotifications()
    }
    
    func tappedDateView(sender: UITapGestureRecognizer?) {
        nextDateShowsDate = !nextDateShowsDate
        NSNotificationCenter.defaultCenter().postNotificationName("toggleNextDateView", object: nil, userInfo: ["nextDateShowsDate": nextDateShowsDate])
    }
    
    @objc func updateNextDate() {
        XenimAPI.fetchEvents(podcastId: podcast.id, status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in
            if let event = events.first {
                self.nextEvent = event
            }
            dispatch_async(dispatch_get_main_queue(), { 
                self.updateNextDateLabel()
            })
        }
    }
    
    func updateNextDateLabel() {
        if let event = nextEvent {
            
            // calculate in how many days this event takes place
            let cal = NSCalendar.currentCalendar()
            let today = cal.startOfDayForDate(NSDate())
            let diff = cal.components(NSCalendarUnit.Day,
                                      fromDate: today,
                                      toDate: event.begin,
                                      options: NSCalendarOptions.WrapComponents )
            let days = diff.day
            
            
            if nextDateShowsDate {
                let formatter = NSDateFormatter();
                formatter.locale = NSLocale.currentLocale()
                
                // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
                
                formatter.setLocalizedDateFormatFromTemplate("HH:mm")
                let time = formatter.stringFromDate(event.begin)
                nextDateBottomLabel.text = time
                
                if days < 7 {
                    formatter.setLocalizedDateFormatFromTemplate("cccccc")
                    var day = formatter.stringFromDate(event.begin)
                    day = day.stringByReplacingOccurrencesOfString(".", withString: "")
                    day = day.uppercaseString
                    nextDateTopLabel.text = day
                } else {
                    formatter.setLocalizedDateFormatFromTemplate("d.M")
                    let date = formatter.stringFromDate(event.begin)
                    nextDateTopLabel.text = date
                }
            } else {
                nextDateTopLabel.text = "\(days)"
                let daysStringSingle = NSLocalizedString("day", value: "day", comment: "day")
                let daysStringMultiple = NSLocalizedString("days", value: "days", comment: "days")
                if days == 1 {
                    nextDateBottomLabel.text = daysStringSingle
                } else {
                    nextDateBottomLabel.text = daysStringMultiple
                }
            }
        } else {
            // no upcoming event
            nextDateTopLabel.text = ""
            nextDateBottomLabel.text = ""
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateNextDate), name: "updateNextDate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleDateView(_:)), name: "toggleNextDateView", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func toggleDateView(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let state = userInfo["nextDateShowsDate"] as? Bool {
                nextDateShowsDate = state
                updateNextDateLabel()
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
