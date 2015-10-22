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
    
    var events = [String:[Event]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        HoersuppeAPI.fetchEvents(count: 50) { (events) -> Void in
            self.events.removeAll()
            self.sortEventsInSections(events)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    private func sortEventsInSections(events: [Event]) {
        for event in events {
            
            if event.livedate != nil {
                let currentDate = NSDate()
                let eventStartDate = event.livedate!
                let duration: NSTimeInterval = (Double)(event.duration * 60)
                let eventEndDate = event.livedate!.dateByAddingTimeInterval(duration) // event.duration is minutes
            
                if eventStartDate.earlierDate(currentDate) == eventStartDate && eventEndDate.laterDate(currentDate) == eventEndDate {
                    // live now
                    addEvent(event, section: "Live")
                } else {
                    // upcoming
                    addEvent(event, section: "Upcoming")
                }
            }
        }
    }
    
    private func addEvent(event: Event, section: String) {
        if events.keys.contains(section) {
            events[section]?.append(event)
        } else {
            events[section] = [event]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return events.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let key = Array(events.keys)[section]
        if let count = events[key]?.count {
            return count
        } else {
            return Int(0)
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(events.keys)[section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Event", forIndexPath: indexPath) as! EventTableViewCell
        
        let key = Array(events.keys)[indexPath.section]
        if let events = events[key] {
            cell.event = events[indexPath.row]
        }

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
                        destinationVC.podcastName = cell.event?.podcastName
                    default: break
                    }
                }

            }
        }
        
    }
    

}
