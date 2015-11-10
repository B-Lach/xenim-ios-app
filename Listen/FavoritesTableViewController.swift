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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged"), name: "favoritesChanged", object: nil)
        refresh()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func favoritesChanged() {
        refresh()
    }
    
    func refresh() {
        favorites = Favorites.fetch()
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//
//    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell", forIndexPath: indexPath) as! FavoriteTableViewCell
        // configure cell
        cell.podcastSlug = favorites[indexPath.row]
        return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */
    
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            Favorites.remove(slug: favorites[indexPath.row])
            favorites.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    
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
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        
//    }
    
    
}
