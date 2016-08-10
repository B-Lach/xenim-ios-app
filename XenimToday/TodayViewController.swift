//
//  TodayViewController.swift
//  XenimToday
//
//  Created by Stefan Trauth on 08/08/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit
import NotificationCenter
import XenimAPI
import AlamofireImage

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        podcastNameLabel.text = ""
        descriptionLabel.text = ""
        headerLabel.text = ""
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        XenimAPI.fetchEvents(status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in
            DispatchQueue.main.async {
                self.updateUI(event: events.first)
                completionHandler(NCUpdateResult.newData)
            }
        }
    }
    
    func updateUI(event: Event?) {
        // hide views appropriately
        coverartImageView.isHidden = event == nil
        podcastNameLabel.isHidden = event == nil
        descriptionLabel.isHidden = event == nil
        playButton.isHidden = event == nil
        headerLabel.isHidden = event == nil
        infoLabel.isHidden = event != nil
        
        if let event = event {
            podcastNameLabel.text = event.podcast.name
            if let artworkURL = event.podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(artworkURL)
            }
            descriptionLabel.text = event.eventDescription
            
            if event.isLive() {
                headerLabel.text = "Live Now"
            } else {
                headerLabel.text = "In \(timeLeftString(until: event.begin))"
            }
        }
    }
    
    func timeLeftString(until eventDate: Date) -> String {
        
        let cal = Calendar.current
        let now = Date()
        
        let diff = cal.dateComponents([.day, .hour, .minute], from: now, to: eventDate)
        let hoursLeft = diff.hour!
        let minutesLeft = diff.minute!
        let daysLeft = diff.day!
        
        // check if there are less than 24 hours left
        // use absolute value here to make it also work for negative values if a show is overdue
        if abs(minutesLeft) < 1440 {
            // check if thre are less than 1 hour left
            if abs(minutesLeft) < 60 {
                // show minutes left
                // could be negative!
                let minutesString = NSLocalizedString("minute", value: "min", comment: "min")
                return "\(minutesLeft)\(minutesString)"
            } else {
                // show hours left
                let hoursStringSingle = NSLocalizedString("hour", value: "hour", comment: "hour")
                let hoursStringMultiple = NSLocalizedString("hours", value: "hours", comment: "hours")
                if hoursLeft == 1 {
                    return "\(hoursLeft) \(hoursStringSingle)"
                } else {
                    return "\(hoursLeft) \(hoursStringMultiple)"
                }
            }
        } else {
            // show days left
            let daysStringSingle = NSLocalizedString("day", value: "day", comment: "day")
            let daysStringMultiple = NSLocalizedString("days", value: "days", comment: "days")
            if daysLeft == 1 {
                return "\(daysLeft) \(daysStringSingle)"
            } else {
                return "\(daysLeft) \(daysStringMultiple)"
            }
        }

    }
    
}
