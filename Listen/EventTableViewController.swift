//
//  LiveEventTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import AlamofireImage

class EventTableViewController: UITableViewController {
    
    @IBOutlet weak var spinner: UIRefreshControl!
    enum Section {
        case Live
        case Today
        case Tomorrow
        case ThisWeek
        case Later
    }
    var events = [[Event](),[Event](),[Event](),[Event](),[Event]()]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh(spinner)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    private func sortEventsInSections(events: [Event]) {
        for event in events {
            
            if event.livedate != nil {
                let now = NSDate()
                let eventStartDate = event.livedate!
                let duration: NSTimeInterval = (Double)(event.duration * 60)
                let eventEndDate = event.livedate!.dateByAddingTimeInterval(duration) // event.duration is minutes
            
                let calendar = NSCalendar.currentCalendar()
                
                if eventEndDate.earlierDate(now) == eventEndDate {
                    // event already finished, do not add to the list
                } else if eventStartDate.earlierDate(now) == eventStartDate && eventEndDate.laterDate(now) == eventEndDate {
                    // live now
                    addEvent(event, section: Section.Live)
                } else if calendar.isDateInToday(eventStartDate) {
                    // today
                    addEvent(event, section: Section.Today)
                } else if calendar.isDateInTomorrow(eventStartDate) {
                    // tomorrow
                    addEvent(event, section: Section.Tomorrow)
                } else if calendar.isDateInWeekend(eventStartDate) {
                    // this week
                    addEvent(event, section: Section.ThisWeek)
                } else {
                    // upcoming
                    addEvent(event, section: Section.Later)
                }
            }
        }
    }
    
    private func addEvent(event: Event, section: Section) {
        switch section {
            case .Live: events[0].append(event)
            case .Today: events[1].append(event)
            case .Tomorrow: events[2].append(event)
            case .ThisWeek: events[3].append(event)
            case .Later: events[4].append(event)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refresh(spinner: UIRefreshControl) {
        spinner.beginRefreshing()
        HoersuppeAPI.fetchEvents(count: 50) { (events) -> Void in
            self.events = [[Event](),[Event](),[Event](),[Event](),[Event]()]
            self.sortEventsInSections(events)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                spinner.endRefreshing()
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return events.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return events[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0: return "Live now"
            case 1: return "Today"
            case 2: return "Tomorrow"
            case 3: return "This Week"
            case 4: return "Later"
            default: return "Unknown"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Event", forIndexPath: indexPath) as! EventTableViewCell
        cell.event = events[indexPath.section][indexPath.row]
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let cell = sender as? EventTableViewCell {
            if let destinationVC = segue.destinationViewController as? PodcastDetailViewController {
                if let identifier = segue.identifier {
                    switch identifier {
                    case "PodcastDetail":
                        //destinationVC.podcast = cell.event?.podcast
                        destinationVC.podcastName = cell.event?.podcastSlug
                    default: break
                    }
                }

            }
        }
        
    }
    

}