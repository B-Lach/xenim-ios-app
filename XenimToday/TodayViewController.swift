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
    @IBOutlet weak var dateTopLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var dateBottomLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        podcastNameLabel.text = ""
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
        infoLabel.isHidden = event != nil
        
        if let event = event {
            podcastNameLabel.text = event.podcast.name
            if let artworkURL = event.podcast.artwork.thumb180Url {
                coverartImageView.af_setImageWithURL(artworkURL)
            }
            
            if event.isLive() {
                
            } else {
                
            }
        }
    }
    
}
