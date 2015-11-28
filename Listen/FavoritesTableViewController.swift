//
//  LiveEventTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoritesTableViewController: UITableViewController {
    
    var favorites = [String]()
    var messageVC: MessageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged"), name: "favoritesChanged", object: nil)
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            tableView.backgroundView = messageVC.view
        }
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        // increase content inset for audio player
        tableView.contentInset.bottom = tableView.contentInset.bottom + 40
        
        refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    func favoritesChanged() {
        refresh()
    }
    
    func refresh() {
        favorites = Favorites.fetch()
        favorites.sortInPlace()
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        updateBackground()
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell", forIndexPath: indexPath) as! FavoriteTableViewCell
        // configure cell
        cell.podcastSlug = favorites[indexPath.row]
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            Favorites.remove(slug: favorites[indexPath.row])
        }
    }
    
    func updateBackground() {
        if favorites.count == 0 {
            messageVC?.messageLabel.text = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            tableView.backgroundView?.hidden = false
        } else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView?.hidden = true
        }
    }
    
    
    @IBAction func dismissSettings(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func dismissAddFavorite(segue:UIStoryboardSegue) {
        
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "PodcastDetail" {
            if let cell = sender as? FavoriteTableViewCell {
                if cell.podcast == nil {
                    return false
                }
            }
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dvc = segue.destinationViewController as? PodcastDetailViewController {
            if segue.identifier == "PodcastDetail" {
                if let cell = sender as? FavoriteTableViewCell {
                    if let podcast = cell.podcast {
                        dvc.podcast = podcast
                    }
                }
            }
        }
    }
    
    
}
