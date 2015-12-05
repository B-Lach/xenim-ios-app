//
//  LiveEventTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

protocol EventDetailDelegate {
    func showEventInfo(event event: Event)
}

class EventTableViewController: UITableViewController, EventDetailDelegate {
    
    // possible sections
    enum Section {
        case Live
        case Today
        case Tomorrow
        case ThisWeek
        case Later
    }
    
    // all events with no sorting
    var unsortedEvents = [Event]()
    // events sorted into sections (see above) and sorted by time
    var events = [[Event](),[Event](),[Event](),[Event](),[Event]()]
    // same as events, but filtered by current favorites
    var favoriteEvents = [[Event](),[Event](),[Event](),[Event](),[Event]()]
    
    // toggle to show favorites only
    var showFavoritesOnly = false
    @IBOutlet weak var filterFavoritesBarButtonItem: UIBarButtonItem!
    
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
        }
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            tableView.backgroundView = messageVC.view
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)

        refresh(spinner)
        updateFilterFavoritesButton()
        
        // setup timer to update every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("timerTicked"), userInfo: nil, repeats: true)
        
        // setup the player managers view controllers which are required
        PlayerManager.sharedInstance.baseViewController = self.tabBarController
        PlayerManager.sharedInstance.eventDetailDelegate = self
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
    }
    
    // MARK: - Update UI
    
    func updateFilterFavoritesButton() {
        if showFavoritesOnly {
            filterFavoritesBarButtonItem?.image = UIImage(named: "corn-25-star")
        } else {
            filterFavoritesBarButtonItem?.image = UIImage(named: "corn-25-star-o")
        }
    }
    
    func updateBackground() {
        let messageLabel = messageVC?.messageLabel
        if numberOfRows() == 0 {
            if showFavoritesOnly {
                messageLabel?.text = NSLocalizedString("event_tableview_empty_favorites_only_message", value: "None of your favorite podcast shows will be live in the near future. Add more shows to your favorites to see something here.", comment: "this message gets displayed if the user filters the event tableview to only show favorites, but there are not events to display.")
            } else {
                messageLabel?.text = NSLocalizedString("event_tableview_empty_message", value: "Did no receive any upcoming events.", comment: "this message gets displayed if no events could be displayed / fetched from the API")
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
        HoersuppeAPI.fetchEvents(count: 50) { (events) -> Void in
            self.unsortedEvents = events
            self.resortEvents()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                spinner.endRefreshing()
            })
        }
    }
    
    @IBAction func toggleFilter(sender: UIBarButtonItem) {
        showFavoritesOnly = !showFavoritesOnly
        userDefaults.setObject(showFavoritesOnly, forKey: userDefaultsFavoritesSettingKey)
        updateFilterFavoritesButton()
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
            return unsortedEvents.count
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "★") { (action, indexPath) -> Void in
            if self.showFavoritesOnly {
                let event = self.favoriteEvents[indexPath.section][indexPath.row]
                Favorites.toggle(slug: event.podcastSlug)
            } else {
                let event = self.events[indexPath.section][indexPath.row]
                Favorites.toggle(slug: event.podcastSlug)
            }
            tableView.setEditing(false, animated: true)
        }
        shareAction.backgroundColor = UIColor(red:0.93, green:0.76, blue:0, alpha:1)
        return [shareAction]
    }
    
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
    
    private func addEvent(event: Event, section: Section) {
        switch section {
        case .Live: events[0].append(event)
        case .Today: events[1].append(event)
        case .Tomorrow: events[2].append(event)
        case .ThisWeek: events[3].append(event)
        case .Later: events[4].append(event)
        }
    }
    
    private func sortEventsInSections(events: [Event]) {
        for event in events {
            if event.isFinished() {
                // event already finished, do not add to the list
            } else if event.isLive() {
                addEvent(event, section: Section.Live)
            } else if event.isToday() {
                addEvent(event, section: Section.Today)
            } else if event.isTomorrow() {
                addEvent(event, section: Section.Tomorrow)
            } else if event.isThisWeek() {
                addEvent(event, section: Section.ThisWeek)
            } else {
                addEvent(event, section: Section.Later)
            }
        }
    }
    
    private func resortEvents() {
        self.events = [[Event](),[Event](),[Event](),[Event](),[Event]()]
        self.sortEventsInSections(unsortedEvents)
        if self.showFavoritesOnly {
            self.filterFavorites()
        }
    }
    
    private func filterFavorites() {
        favoriteEvents = events
        let favorites = Favorites.fetch()
        
        for i in 0 ..< favoriteEvents.count {
            let section = favoriteEvents[i]
            favoriteEvents[i] = section.filter({ (event) -> Bool in
                return favorites.contains(event.podcastSlug)
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
                        destinationVC.event = cell.event
                    } else if let event = sender as? Event {
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
    
    // MARK: - delegate
    
    // if the info button in the player for a specific event is pressed
    // this table view controller should segue to the event detail view
    func showEventInfo(event event: Event) {
        // switch to event detail view
        tabBarController?.selectedViewController = self.navigationController
        
        // minify the player
        tabBarController?.closePopupAnimated(true, completion: nil)
        
        if let podcastDetailVC = self.navigationController?.visibleViewController as? PodcastDetailViewController {
            if podcastDetailVC.event != event {
                // there is already a detail view open, but with the wrong event
                // so we close it
                self.navigationController?.popViewControllerAnimated(false)
                // and open the correct one
                performSegueWithIdentifier("PodcastDetail", sender: event)
            }
            // else the correct info is already present
        } else {
            // there is no detail view open yet, so just open it
            performSegueWithIdentifier("PodcastDetail", sender: event)
        }
    }
    
    // MARK: - timer
    
    // update events every minute automatically
    @objc func timerTicked() {
        resortEvents()
        tableView.reloadData()
    }
    
}
