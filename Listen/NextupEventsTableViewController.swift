//
//  NextupEventsTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class NextupEventsTableViewController: UITableViewController {
    
    var upcomingEvents = [Event]()
    var podcastId: String!
    var isLoading = true
    @IBOutlet weak var addToFavoritesInformationLabel: UILabel!
    
    // static configs for this view
    let upcomingEventCount = 3
    let viewHeight : CGFloat = 3*44 + 100
    
    override var preferredContentSize: CGSize {
        get {
            return CGSizeMake(super.preferredContentSize.width, viewHeight)
            
//            // tried to set the height dynamically based on content height, but did not work out
//            let height = CGFloat(upcomingEvents.count) * tableView.rowHeight
//            return CGSize(width: super.preferredContentSize.width, height: height)
        }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Favorites.fetch().contains(podcastId) {
            addToFavoritesInformationLabel.text = NSLocalizedString("nextup_events_popupview_information_label_if_favorite", value: "You will receive push notifications.", comment: "Message shown in nextup popup view controller as info message at the end of the table if the user has already added this podcast to his favorites. Text should be like 'You will receive push notifications'.")
        }
        
        // fetch upcoming events
        XenimAPI.fetchPodcastUpcomingEvents(podcastId, maxCount: upcomingEventCount) { (events) -> Void in
            let filteredEvents = events.filter({ (event) -> Bool in
                event.isUpcoming()
            })
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.upcomingEvents = filteredEvents
                self.tableView.reloadData()
                self.isLoading = false
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return 1 row at least. if no data is available the "no data" cell is shown.
        return max(upcomingEvents.count, 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if upcomingEvents.count > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UpcomingEvent", forIndexPath: indexPath)
            
            let event = upcomingEvents[indexPath.row]
            
            // format livedate
            let formatter = NSDateFormatter();
            formatter.locale = NSLocale.currentLocale()
            formatter.setLocalizedDateFormatFromTemplate("EEEE dd.MM HH:mm")
            
            // calculate in how many days this event takes place
            let cal = NSCalendar.currentCalendar()
            let today = cal.startOfDayForDate(NSDate())
            let diff = cal.components(NSCalendarUnit.Day,
                fromDate: today,
                toDate: event.begin,
                options: NSCalendarOptions.WrapComponents )
            
            // setup cell
            cell.textLabel?.text = formatter.stringFromDate(event.begin)
            if event.isUpcomingToday() {
                cell.detailTextLabel?.text = NSLocalizedString("Today", value: "Today", comment: "Today").lowercaseString
            } else {
                let diffDaysString = String(format: NSLocalizedString("podcast_detailview_diff_date_string", value: "in %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), diff.day)
                cell.detailTextLabel?.text = diffDaysString
            }
            return cell
        } else {
            if isLoading {
                // display loading message cell
                let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath)
                return cell
            }
            
            // display no shows scheduled info message cell
            let cell = tableView.dequeueReusableCellWithIdentifier("NoEvents", forIndexPath: indexPath)
            return cell
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
