//
//  FavoritesTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit
import UserNotifications
import Parse
import XenimAPI

class FavoritesTableViewController: UITableViewController{
    
    static let updateNextDateNotification = Notification.Name("updateNextDate")
    
    // contains the podcast slugs of all favorites
    var favorites = [Podcast]()
    var messageVC: MessageViewController?
    var loadingVC: UIViewController?

    @IBOutlet weak var pushNotificationsStatusLabel: UILabel!
    @IBOutlet weak var addFavoriteBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.splitViewController?.preferredDisplayMode = .allVisible
        
        addFavoriteBarButtonItem.accessibilityLabel = NSLocalizedString("voiceover_add_favorite_button_label", value: "Add", comment: "")
        addFavoriteBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_add_favorite_button_hint", value: "Double Tap to search through all podcasts and add favorites", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesTableViewController.favoriteAdded(_:)), name: Favorites.favoriteAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesTableViewController.favoriteRemoved(_:)), name: Favorites.favoriteRemovedNotification, object: nil)
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewController(withIdentifier: "MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            self.messageVC?.message = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
        }
        loadingVC = storyboard?.instantiateViewController(withIdentifier: "LoadingViewController")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // update the push notifications status label, so the user knows if he will receive push notifications
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.async(execute: { 
                if settings.authorizationStatus == .authorized && PFInstallation.current()?.deviceToken != nil {
                    self.pushNotificationsStatusLabel.text = NSLocalizedString("notifications_enabled", comment: "label in favorites table view which tells the user that his notifications are setup correctly")
                } else {
                    self.pushNotificationsStatusLabel.text = NSLocalizedString("notifications_disabled", comment: "label in favorites table view which tells the user that he can not receive notifications because they are not setup correctly")
                }
            })
        }
        
        refresh()
        // refresh next show date label in all cells
        NotificationCenter.default.post(name: FavoritesTableViewController.updateNextDateNotification, object: nil, userInfo: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as! FavoriteTableViewCell
        cell.podcast = favorites[(indexPath as NSIndexPath).row]
        return cell
    }
    
    func favoriteAdded(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // fetch podcast info
            XenimAPI.fetchPodcast(podcastId: podcastId, onComplete: { (newPodcast) -> Void in
                // find the right place to insert it
                if let newPodcast = newPodcast {
                    
                    let index = self.favorites.orderedIndexOf(newPodcast, isOrderedBefore: <)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        // add the new podcast to data source
                        self.favorites.insert(newPodcast, at: index)
                        // update tableview
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.left)
                        self.tableView.endUpdates()
                        self.updateBackground()
                    })
                }
            })

        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        // extract which favorite was deleted
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // find the correct podcast in data source
            for (index, podcast) in favorites.enumerated() {
                if podcast.id == podcastId {
                    // remove it drom data source and tableview
                    favorites.remove(at: index)
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.left)
                    tableView.endUpdates()
                    break
                }
            }
            // there might be 0 elements now, so show message if required
            updateBackground()
        }

    }
    
    func refresh() {
        tableView.backgroundView = loadingVC!.view
        updateBackground()
        
        Favorites.fetchFavoritePodcasts({ (podcasts) -> Void in
            self.favorites = podcasts
            self.favorites.sort()
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.fade)
                self.tableView.backgroundView = self.messageVC!.view
                self.updateBackground()
            })
        })
    }
    
    func updateBackground() {
        if favorites.count == 0 {
            tableView?.backgroundView?.isHidden = false
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        } else {
            tableView?.backgroundView?.isHidden = true
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
    }
    
    // MARK: - Navigation
    
    // rewind segues
    @IBAction func dismissAddFavorite(_ segue:UIStoryboardSegue) {}
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = favorites[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "podcastDetail", sender: podcast)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "podcastDetail" {
            var detail: PodcastDetailTableViewController
            if let navigationController = segue.destination as? UINavigationController {
                detail = navigationController.topViewController as! PodcastDetailTableViewController
            } else {
                detail = segue.destination as! PodcastDetailTableViewController
            }
            
            if let podcast = sender as? Podcast {
                detail.podcast = podcast
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let removeFavoriteAction = UITableViewRowAction(style: .default, title:  NSLocalizedString("remove_favorite", value: "Remove", comment: "remove a favorite by swiping left to edit")) { (action, indexPath) -> Void in
            let podcast = self.favorites[(indexPath as NSIndexPath).row]
            Favorites.toggle(podcastId: podcast.id)
        }
        removeFavoriteAction.backgroundColor = Constants.Colors.tintColor

        return [removeFavoriteAction]
    }

}
