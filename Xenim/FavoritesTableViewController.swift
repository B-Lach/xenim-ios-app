//
//  FavoritesTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoritesTableViewController: UITableViewController{
    
    // contains the podcast slugs of all favorites
    var favorites = [Podcast]()
    var messageVC: MessageViewController?
    var loadingVC: UIViewController?

    @IBOutlet weak var addFavoriteBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.splitViewController?.preferredDisplayMode = .AllVisible
        
        addFavoriteBarButtonItem.accessibilityLabel = NSLocalizedString("voiceover_add_favorite_button_label", value: "Add", comment: "")
        addFavoriteBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_add_favorite_button_hint", value: "Double Tap to search through all podcasts and add favorites", comment: "")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FavoritesTableViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FavoritesTableViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            self.messageVC?.message = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
        }
        loadingVC = storyboard?.instantiateViewControllerWithIdentifier("LoadingViewController")
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
        // refresh next show date label in all cells
        NSNotificationCenter.defaultCenter().postNotificationName("updateNextDate", object: nil, userInfo: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell", forIndexPath: indexPath) as! FavoriteTableViewCell
        cell.podcast = favorites[indexPath.row]
        return cell
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // fetch podcast info
            XenimAPI.fetchPodcast(podcastId: podcastId, onComplete: { (newPodcast) -> Void in
                // find the right place to insert it
                if let newPodcast = newPodcast {
                    
                    let index = self.favorites.orderedIndexOf(newPodcast, isOrderedBefore: <)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        // add the new podcast to data source
                        self.favorites.insert(newPodcast, atIndex: index)
                        // update tableview
                        self.tableView.beginUpdates()
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Left)
                        self.tableView.endUpdates()
                        self.updateBackground()
                    })
                }
            })

        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        // extract which favorite was deleted
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // find the correct podcast in data source
            for (index, podcast) in favorites.enumerate() {
                if podcast.id == podcastId {
                    // remove it drom data source and tableview
                    favorites.removeAtIndex(index)
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Left)
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
            self.favorites.sortInPlace()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.backgroundView = self.messageVC!.view
                self.updateBackground()
            })
        })
    }
    
    func updateBackground() {
        if favorites.count == 0 {
            tableView?.backgroundView?.hidden = false
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            tableView?.backgroundView?.hidden = true
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
    }
    
    // MARK: - Navigation
    
    // rewind segues
    @IBAction func dismissAddFavorite(segue:UIStoryboardSegue) {}
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let podcast = favorites[indexPath.row]
        self.performSegueWithIdentifier("podcastDetail", sender: podcast)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "podcastDetail" {
            var detail: PodcastDetailTableViewController
            if let navigationController = segue.destinationViewController as? UINavigationController {
                detail = navigationController.topViewController as! PodcastDetailTableViewController
            } else {
                detail = segue.destinationViewController as! PodcastDetailTableViewController
            }
            
            if let podcast = sender as? Podcast {
                detail.podcast = podcast
            }
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let removeFavoriteAction = UITableViewRowAction(style: .Default, title:  NSLocalizedString("remove_favorite", value: "Remove", comment: "remove a favorite by swiping left to edit")) { (action, indexPath) -> Void in
            let podcast = self.favorites[indexPath.row]
            Favorites.toggle(podcastId: podcast.id)
        }
        removeFavoriteAction.backgroundColor = Constants.Colors.tintColor

        return [removeFavoriteAction]
    }

}
