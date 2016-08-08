//
//  LiveEventTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import XenimAPI

protocol PlayerDelegate {
    func play(_ event: Event)
}

class EventTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, PlayerDelegate {
    
    static let refreshEventsNotification = Notification.Name("refreshEvents")
    
    // possible sections
    enum Section {
        case today
        case thisWeek
        case later
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
    let userDefaults = UserDefaults.standard
    let userDefaultsFavoritesSettingKey = "showFavoritesOnly"
    
    // background view for message when no data is available
    var messageVC: MessageViewController?
    
    var playerViewController: PlayerViewController?
    
    // MARK: - init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.splitViewController?.preferredDisplayMode = .allVisible
        
        // check if filter was enabled when the app was use the last time
        // fetch it from user defaults
        if let favoritesFilterSetting = userDefaults.object(forKey: userDefaultsFavoritesSettingKey) as? Bool {
            showFavoritesOnly = favoritesFilterSetting
            segmentControl.selectedSegmentIndex = showFavoritesOnly ? 1 : 0
            
        }
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewController(withIdentifier: "MessageViewController") as? MessageViewController {
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
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            tableView.backgroundView?.isHidden = true
        }
    }
    
    // MARK: Actions
    
    @IBAction func refresh(_ spinner: UIRefreshControl) {
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
            
            DispatchQueue.main.async(execute: { 
                self.events = newEvents
                self.refreshControl!.endRefreshing()
                self.filterFavorites()
                
                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0, self.events.count).toRange()!), with: UITableViewRowAnimation.fade)
            })
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            showFavoritesOnly = false
        } else {
            showFavoritesOnly = true
        }
        userDefaults.set(showFavoritesOnly, forKey: userDefaultsFavoritesSettingKey)
        self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0, self.events.count).toRange()!), with: UITableViewRowAnimation.fade)
    }
    
    // MARK: - Notifications
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(EventTableViewController.favoriteAdded(_:)), name: Favorites.favoriteAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EventTableViewController.favoriteRemoved(_:)), name: Favorites.favoriteRemovedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EventTableViewController.refresh(_:)), name: EventTableViewController.refreshEventsNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func favoriteAdded(_ notification: Notification) {
        filterFavorites()
        if showFavoritesOnly {
            self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0, self.events.count).toRange()!), with: UITableViewRowAnimation.fade)
        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        filterFavorites()
        if showFavoritesOnly {
            self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0, self.events.count).toRange()!), with: UITableViewRowAnimation.fade)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        updateBackground()
        if showFavoritesOnly {
            return favoriteEvents.count
        }
        return events.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        if showFavoritesOnly {
            cell.event = favoriteEvents[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        } else {
            cell.event = events[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        }
        cell.playerDelegate = self
        return cell
    }
    
    // helper method because calling tableView.numberOfRowsInSection(section) crashes the app
    private func numberOfRowsInSection(_ section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let toggleFavoriteAction = UITableViewRowAction(style: .default, title: "★") { (action, indexPath) -> Void in
            let cell = self.tableView.cellForRow(at: indexPath) as! EventTableViewCell
            Favorites.toggle(podcastId: cell.event.podcast.id)
            self.tableView.isEditing = false
        }
        toggleFavoriteAction.backgroundColor = Constants.Colors.tintColor
        
        return [toggleFavoriteAction]
    }

    
    // MARK: - Navigation
    
    @IBAction func dismissPlayer(_ segue:UIStoryboardSegue) {}
    
    func play(_ event: Event) {
        self.performSegue(withIdentifier: "play", sender: event)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! EventTableViewCell
        self.performSegue(withIdentifier: "podcastDetail", sender: cell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "play" {
            if let navigationController = segue.destination as? UINavigationController {
                if let playerVC = navigationController.topViewController as? PlayerViewController {
                    if let event = sender as? Event {
                        playerVC.event = event
                    }
                }
            }

        }
        
        if segue.identifier == "podcastDetail" {
            var detail: PodcastDetailTableViewController
            if let navigationController = segue.destination as? UINavigationController {
                detail = navigationController.topViewController as! PodcastDetailTableViewController
            } else {
                detail = segue.destination as! PodcastDetailTableViewController
            }
            
            if let cell = sender as? EventTableViewCell {
                detail.podcast = cell.event.podcast
            }
        }
    }
    
}
