//
//  LiveEventTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

protocol PlayerDelegate {
    func play(event: Event)
}

class EventTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, PlayerDelegate {
    
    // possible sections
    enum Section {
        case Today
        case ThisWeek
        case Later
    }

    // events sorted into sections (see above) and sorted by time
    var events = [[Event](),[Event](),[Event]()]
    // same as events, but filtered by current favorites
    var favoriteEvents = [[Event](),[Event](),[Event]()]
    
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

        self.splitViewController?.preferredDisplayMode = .AllVisible
        
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
        var newEvents = [[Event](),[Event](),[Event]()]
        
        XenimAPI.fetchEvents(status: ["RUNNING", "UPCOMING"], maxCount: 50) { (events) in
            for event in events {
                if event.isLive() || event.isUpcomingToday() {
                    newEvents[0].append(event)
                } else if event.isUpcomingThisWeek() {
                    newEvents[1].append(event)
                } else if event.isUpcoming() {
                    newEvents[2].append(event)
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.events = newEvents
                self.refreshControl!.endRefreshing()
                self.filterFavorites()
                
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
        filterFavorites()
        if showFavoritesOnly {
            self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.events.count)), withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        filterFavorites()
        if showFavoritesOnly {
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
        case 0: return NSLocalizedString("event_tableview_sectionheader_live", value: "Today", comment: "section header in event table view for the live now section")
        case 1: return NSLocalizedString("event_tableview_sectionheader_thisweek", value: "This Week", comment: "section header in event table view for the later this week section")
        case 2: return NSLocalizedString("event_tableview_sectionheader_later", value: "Later", comment: "section header in event table view for the later than next week section")
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
        cell.playerDelegate = self
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
    
    @IBAction func dismissPlayer(segue:UIStoryboardSegue) {}
    
    func play(event: Event) {
        self.performSegueWithIdentifier("play", sender: event)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EventTableViewCell
        self.performSegueWithIdentifier("podcastDetail", sender: cell)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "play" {
            if let navigationController = segue.destinationViewController as? UINavigationController {
                if let playerVC = navigationController.topViewController as? PlayerViewController {
                    if let event = sender as? Event {
                        playerVC.event = event
                    }
                }
            }

        }
        
        if segue.identifier == "podcastDetail" {
            var detail: PodcastDetailTableViewController
            if let navigationController = segue.destinationViewController as? UINavigationController {
                detail = navigationController.topViewController as! PodcastDetailTableViewController
            } else {
                detail = segue.destinationViewController as! PodcastDetailTableViewController
            }
            
            if let cell = sender as? EventTableViewCell {
                detail.podcast = cell.event.podcast
            }
        }
    }
    
}
