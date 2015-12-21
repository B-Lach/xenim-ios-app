//
//  LiveEventTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventTableViewController: UITableViewController {
    
    // possible sections
    enum Section {
        case Live
        case Today
        case Tomorrow
        case ThisWeek
        case Later
    }

    // events sorted into sections (see above) and sorted by time
    var events = [[Event](),[Event](),[Event](),[Event](),[Event]()]
    // same as events, but filtered by current favorites
    var favoriteEvents = [[Event](),[Event](),[Event](),[Event](),[Event]()]
    
    // toggle to show favorites only
    var showFavoritesOnly = false
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var spinner: UIRefreshControl!
    
    // user defaults to store favorites filter enabled status
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let userDefaultsFavoritesSettingKey = "showFavoritesOnly"
    
    var timer : NSTimer? // timer to update view periodically
    let updateInterval: NSTimeInterval = 60 // seconds
    
    // background view for message when no data is available
    var messageVC: MessageViewController?
    
    var playerViewController: PlayerViewController?
    
    // MARK: - init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        // increase content inset for audio player
        tableView.contentInset.bottom = tableView.contentInset.bottom + 40
        
        // check if filter was enabled when the app was use the last time
        // fetch it from user defaults
        if let favoritesFilterSetting = userDefaults.objectForKey(userDefaultsFavoritesSettingKey) as? Bool {
            showFavoritesOnly = favoritesFilterSetting
            segmentControl.selectedSegmentIndex = showFavoritesOnly ? 1 : 0
            
        }
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            tableView.backgroundView = messageVC.view
            tableView.backgroundView?.layer.zPosition -= 1
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)

        refresh(spinner)
        
        // setup timer to update every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("timerTicked"), userInfo: nil, repeats: true)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
    }
    
    // MARK: - Update UI
    
    func updateBackground() {
        let messageLabel = messageVC?.messageLabel
        if numberOfRows() == 0 {
            if showFavoritesOnly {
                messageLabel?.text = NSLocalizedString("event_tableview_empty_favorites_only_message", value: "This is a filtered event list. You only see events of your favorite shows here. Currently there are no events of your favorite podcasts scheduled.", comment: "this message gets displayed if the user filters the event tableview to only show favorites, but there are not events to display.")
            } else {
                messageLabel?.text = NSLocalizedString("event_tableview_empty_message", value: "Did not receive any upcoming events. Pull to refresh to try again.", comment: "this message gets displayed if no events could be displayed / fetched from the API")
            }
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            tableView.backgroundView?.hidden = false
        } else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView?.hidden = true
        }
    }
    
    // MARK: Actions
    
    @IBAction func refresh(spinner: UIRefreshControl) {
        spinner.beginRefreshing()
        events = [[Event](),[Event](),[Event](),[Event](),[Event]()]
        
        let serviceGroup = dispatch_group_create()
        
        dispatch_group_enter(serviceGroup)
        XenimAPI.fetchUpcomingEvents(maxCount: 50) { (events) -> Void in
            for event in events {
                if event.isToday() {
                    self.addEventToSection(event, section: Section.Today)
                } else if event.isTomorrow() {
                    self.addEventToSection(event, section: Section.Tomorrow)
                } else if event.isThisWeek() {
                    self.addEventToSection(event, section: Section.ThisWeek)
                } else {
                    self.addEventToSection(event, section: Section.Later)
                }
            }
            dispatch_group_leave(serviceGroup)
        }
        dispatch_group_enter(serviceGroup)
        XenimAPI.fetchLiveEvents { (events) -> Void in
            for event in events {
                self.addEventToSection(event, section: Section.Live)
            }
            dispatch_group_leave(serviceGroup)
        }
        
        dispatch_group_notify(serviceGroup, dispatch_get_main_queue()) { () -> Void in
            self.tableView.reloadData()
            spinner.endRefreshing()
        }
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            showFavoritesOnly = false
        } else {
            showFavoritesOnly = true
        }
        
        userDefaults.setObject(showFavoritesOnly, forKey: userDefaultsFavoritesSettingKey)
        if showFavoritesOnly {
            filterFavorites()
        }
        tableView.reloadData()
    }
    
    // MARK: - Notifications
    
    func favoritesChanged(notification: NSNotification) {
        if showFavoritesOnly {
            filterFavorites()
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        updateBackground()
        if showFavoritesOnly {
            return favoriteEvents.count
        }
        return events.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfRowsInSection(section) == 0 {
            // hide the section header for sections with no content
            return nil
        }
        switch section {
        case 0: return NSLocalizedString("event_tableview_sectionheader_live", value: "Live now", comment: "section header in event table view for the live now section")
        case 1: return NSLocalizedString("event_tableview_sectionheader_today", value: "Upcoming Today", comment: "section header in event table view for the upcoming today section")
        case 2: return NSLocalizedString("event_tableview_sectionheader_tomorrow", value: "Tomorrow", comment: "section header in event table view for the tomorrow section")
        case 3: return NSLocalizedString("event_tableview_sectionheader_thisweek", value: "Later this Week", comment: "section header in event table view for the later this week section")
        case 4: return NSLocalizedString("event_tableview_sectionheader_later", value: "Next week and later", comment: "section header in event table view for the later than next week section")
        default: return "Unknown"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Event", forIndexPath: indexPath) as! EventTableViewCell
        if showFavoritesOnly {
            cell.event = favoriteEvents[indexPath.section][indexPath.row]
        } else {
            cell.event = events[indexPath.section][indexPath.row]
        }
        return cell
    }
    
    // helper method because calling tableView.numberOfRowsInSection(section) crashes the app
    private func numberOfRowsInSection(section: Int) -> Int {
        if showFavoritesOnly {
            return favoriteEvents[section].count
        }
        return events[section].count
    }
    
    private func numberOfRows() -> Int {
        if showFavoritesOnly {
            var count = 0
            for section in favoriteEvents {
                count += section.count
            }
            return count
        } else {
            var count = 0
            for section in events {
                count += section.count
            }
            return count
        }
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
    
    // MARK: process data
    
    private func addEventToSection(event: Event, section: Section) {
        objc_sync_enter(events)
        switch section {
        case .Live: events[0].append(event)
        case .Today: events[1].append(event)
        case .Tomorrow: events[2].append(event)
        case .ThisWeek: events[3].append(event)
        case .Later: events[4].append(event)
        }
        objc_sync_exit(events)
    }
    
    private func filterFavorites() {
        favoriteEvents = events
        let favorites = Favorites.fetch()
        
        for i in 0 ..< favoriteEvents.count {
            let section = favoriteEvents[i]
            favoriteEvents[i] = section.filter({ (event) -> Bool in
                return favorites.contains(event.podcast.id)
            })
        }
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationVC = segue.destinationViewController as? PodcastDetailViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case "PodcastDetail":
                    if let cell = sender as? EventTableViewCell {
                        // this is the case when the segue is caused by the user tappin on a cell
                        destinationVC.event = cell.event
                    } else if let event = sender as? Event {
                        // this is the case for showEventInfo delegate method.
                        destinationVC.event = event
                    }
                default: break
                }
            }
        }
        
    }
    
    @IBAction func dismissSettings(segue:UIStoryboardSegue) {
        // do nothing
    }
    
    // MARK: - static global
    
    // if the info button in the player for a specific event is pressed
    // this table view controller should segue to the event detail view
    static func showEventInfo(event event: Event) {
        if let tabBarController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UITabBarController {
            // switch to event detail view
            tabBarController.selectedIndex = 0
            
            // minify the player
            tabBarController.closePopupAnimated(true, completion: nil)
            
            if let navigationController = tabBarController.childViewControllers.first as? UINavigationController {
                if let podcastDetailVC = navigationController.visibleViewController as? PodcastDetailViewController {
                    if !podcastDetailVC.event!.equals(event) {
                        // there is already a detail view open, but with the wrong event
                        // so we close it
                        navigationController.popViewControllerAnimated(false)
                        // and open the correct one
                        if let eventTableViewController = navigationController.visibleViewController as? EventTableViewController {
                            eventTableViewController.performSegueWithIdentifier("PodcastDetail", sender: event)
                        }
                    }
                    // else the correct info is already present
                } else if let eventTableViewController = navigationController.visibleViewController as? EventTableViewController {
                    // there is no detail view open yet, so just open it
                    eventTableViewController.performSegueWithIdentifier("PodcastDetail", sender: event)
                }
            }
        }
    }
    
    // MARK: - timer
    
    // update events every minute automatically
    @objc func timerTicked() {
        // TODO
    }
    
}
