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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged"), name: "favoritesChanged", object: nil)
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            tableView?.backgroundView = messageVC.view
        }
        
        // increase content inset for audio player
        tableView?.contentInset.bottom = tableView!.contentInset.bottom + 40
        refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        updateBackground()
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
    
    func favoritesChanged() {
        refresh()
    }
    
    func refresh() {
        Favorites.fetchFavoritePodcasts({ (podcasts) -> Void in
            self.favorites = podcasts
            self.favorites.sortInPlace({ (podcast1, podcast2) -> Bool in
                return podcast1.name < podcast2.name
            })
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView?.reloadData()
            })
        })
    }
    
    func updateBackground() {
        if favorites.count == 0 {
            messageVC?.messageLabel.text = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
            tableView?.backgroundView?.hidden = false
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            tableView?.backgroundView?.hidden = true
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
    }
    
    // MARK: - Navigation
    
    // rewind segues
    @IBAction func dismissSettings(segue:UIStoryboardSegue) {}
    @IBAction func dismissAddFavorite(segue:UIStoryboardSegue) {}
    
    
    // MARK: - Navigation
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        showFavoriteDetailViewForIndexPath(indexPath)
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        showFavoriteDetailViewForIndexPath(indexPath)
    }
    
    func showFavoriteDetailViewForIndexPath(indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // configure event detail view controller as popup content
        let favoriteDetailVC = storyboard.instantiateViewControllerWithIdentifier("FavoriteDetail") as! FavoriteDetailViewController
        favoriteDetailVC.podcast = favorites[indexPath.row]
        
        let window = UIApplication.sharedApplication().delegate?.window!
        PathDynamicModal.show(modalView: favoriteDetailVC, inView: window!)
        
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let removeFavoriteAction = UITableViewRowAction(style: .Default, title: "Remove") { (action, indexPath) -> Void in
            let podcast = self.favorites[indexPath.row]
            Favorites.remove(podcastId: podcast.id)
        }
        removeFavoriteAction.backgroundColor = Constants.Colors.tintColor

        return [removeFavoriteAction]
    }

}
