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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        XenimAPI.fetchEvents(status: ["RUNNING", "UPCOMING"], maxCount: 1) { (events) in
            DispatchQueue.main.async {
                if let event = events.first {
                    self.updateUI(event: event)
                    completionHandler(NCUpdateResult.newData)
                } else {
                    self.infoLabel.text = "no data"
                    completionHandler(NCUpdateResult.noData)
                }
            }
        }
    }
    
    func updateUI(event: Event) {
        if event.isLive() {
            infoLabel.text = event.podcast.name
        } else {
            infoLabel.text = event.podcast.name
        }
    }
    
}
