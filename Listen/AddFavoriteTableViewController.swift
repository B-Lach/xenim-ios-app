//
//  AddFavoriteTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class AddFavoriteTableViewController: UITableViewController, UISearchResultsUpdating {

    var podcasts = [String:String]()
    var filteredPodcasts = [String]()
    var orderedPodcasts = [String]()
    var resultSearchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add search bar
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        tableView.tableHeaderView = resultSearchController.searchBar
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        HoersuppeAPI.fetchAllPodcasts { (podcasts) -> Void in
            self.podcasts = podcasts
            self.orderedPodcasts = Array(podcasts.keys).sort()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.active {
            return max(1, filteredPodcasts.count)
        }
        return max(1, orderedPodcasts.count)
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let dataSource: [String]
        if resultSearchController.active {
            dataSource = filteredPodcasts
        } else {
            dataSource = orderedPodcasts
        }
        
        if dataSource.count > 0 {
            if let cell = tableView.dequeueReusableCellWithIdentifier("PodcastCell", forIndexPath: indexPath) as? PodcastTableViewCell {
                cell.podcastSlug = dataSource[indexPath.row]
                cell.podcastName = podcasts[dataSource[indexPath.row]]
                return cell
            }
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("NoResultsCell", forIndexPath: indexPath)
        return cell
    }
    
    // MARK: search
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filteredPodcasts = self.orderedPodcasts.filter({ (podcastSlug) -> Bool in
            let podcastName = podcasts[podcastSlug]!.lowercaseString
            let stringMatch = podcastName.rangeOfString(searchText.lowercaseString)
            return stringMatch != nil
        })
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
            tableView.reloadData()
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

    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "PodcastDetail2" {
            if let cell = sender as? PodcastTableViewCell {
                if cell.podcast == nil {
                    return false
                }
            }
        }
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dvc = segue.destinationViewController as? PodcastDetailViewController {
            if segue.identifier == "PodcastDetail2" {
                if let cell = sender as? PodcastTableViewCell {
                    if let podcast = cell.podcast {
                        dvc.podcast = podcast
                        resultSearchController.active = false
                    }
                }
            }
        }
    }
    

}
