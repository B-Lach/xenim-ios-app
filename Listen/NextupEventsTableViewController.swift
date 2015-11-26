//
//  NextupEventsTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class NextupEventsTableViewController: UITableViewController {
    
    var upcomingEvents = [Event]()
    var podcastSlug: String!
    let upcomingEventCount = 3
    
    override var preferredContentSize: CGSize {
        get {
            return CGSizeMake(super.preferredContentSize.width, 3*44 + 50)
            
//            let height = CGFloat(upcomingEvents.count) * tableView.rowHeight
//            return CGSize(width: super.preferredContentSize.width, height: height)
        }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        HoersuppeAPI.fetchPodcastNextLiveEvents(podcastSlug, count: upcomingEventCount) { (events) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.upcomingEvents = events
                self.tableView.reloadData()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return upcomingEvents.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UpcomingEvent", forIndexPath: indexPath)
        
        let event = upcomingEvents[indexPath.row]
        let eventDate = event.livedate
        
        // format livedate
        let formatter = NSDateFormatter();
        formatter.locale = NSLocale.currentLocale()
        formatter.setLocalizedDateFormatFromTemplate("EEEE dd.MM HH:mm")
        
        // calculate in how many days this event takes place
        let cal = NSCalendar.currentCalendar()
        let today = cal.startOfDayForDate(NSDate())
        let diff = cal.components(NSCalendarUnit.Day,
            fromDate: today,
            toDate: eventDate,
            options: NSCalendarOptions.WrapComponents )
        
        // setup cell
        cell.textLabel?.text = formatter.stringFromDate(eventDate)
        if event.isToday() {
            cell.detailTextLabel?.text = NSLocalizedString("Today", value: "Today", comment: "Today").lowercaseString
        } else {
            let diffDaysString = String(format: NSLocalizedString("podcast_detailview_diff_date_string", value: "in %d days", comment: "Tells the user in how many dates the event takes place. It is a formatted string like 'in %d days'."), diff.day)
            cell.detailTextLabel?.text = diffDaysString
        }
        return cell
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
