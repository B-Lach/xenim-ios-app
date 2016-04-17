//
//  LiveEventTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class EventTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
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
    
    // background view for message when no data is available
    var messageVC: MessageViewController?
    
    var playerViewController: PlayerViewController?
    
    // MARK: - init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor.clearColor()
        
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
        
        setupNotifications()

        refresh(spinner)
        
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
        refreshControl!.beginRefreshing()
        var newEvents = [[Event](),[Event](),[Event](),[Event](),[Event]()]
        
        XenimAPI.fetchEvents(status: ["RUNNING", "UPCOMING"], orderBy: "pbegin", maxCount: 50) { (events) in
            for event in events {
                if event.isLive() {
                    newEvents[0].append(event)
                } else if event.isUpcomingToday() {
                    newEvents[1].append(event)
                } else if event.isUpcomingTomorrow() {
                    newEvents[2].append(event)
                } else if event.isUpcomingThisWeek() {
                    newEvents[3].append(event)
                } else if event.isUpcoming() {
                    newEvents[4].append(event)
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.events = newEvents
                self.refreshControl!.endRefreshing()
                if self.showFavoritesOnly {
                    self.filterFavorites()
                }
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.events.count)), withRowAnimation: UITableViewRowAnimation.Fade)
            })
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
        self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.events.count)), withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    // MARK: - Notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventTableViewController.refresh(_:)), name: "refreshEvents", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if showFavoritesOnly {
            filterFavorites()
            self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.events.count)), withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if showFavoritesOnly {
            filterFavorites()
            self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.events.count)), withRowAnimation: UITableViewRowAnimation.Fade)
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
    
    
    // MARK: process data
    
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
    
    // MARK: Actions
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let toggleFavoriteAction = UITableViewRowAction(style: .Default, title: "★") { (action, indexPath) -> Void in
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! EventTableViewCell
            Favorites.toggle(podcastId: cell.event.podcast.id)
            self.tableView.editing = false
        }
        toggleFavoriteAction.backgroundColor = Constants.Colors.tintColor
        
        return [toggleFavoriteAction]
    }

    
    // MARK: - Navigation
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // this is required to prevent the popover to be shown as a modal view on iPhone
        return UIModalPresentationStyle.None
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EventTableViewCell
        self.performSegueWithIdentifier("podcastDetail", sender: cell)
        cell.setSelected(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destVC = segue.destinationViewController as? PodcastDetailTableViewController {
            if let cell = sender as? EventTableViewCell {
                destVC.podcast = cell.event.podcast
            }
        }
    }
    
}
