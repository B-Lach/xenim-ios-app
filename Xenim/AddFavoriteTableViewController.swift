//
//  AddFavoriteTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class AddFavoriteTableViewController: UITableViewController, UISearchResultsUpdating {

    // contains all podcasts with slug:title
    var podcasts = [Podcast]()
    // contains podcast slugs filtered by search term
    var filteredPodcasts = [Podcast]()
    // contains all podcast slugs ordered alphabetically
    var orderedPodcasts = [Podcast]()
    var resultSearchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add search bar
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.tintColor = Constants.Colors.tintColor
        resultSearchController.searchBar.setValue("Done", forKey:"_cancelButtonText")
        tableView.tableHeaderView = resultSearchController.searchBar
        
        // dynamic row height
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        // fetch podcast list from API
        refreshControl?.beginRefreshing()
        XenimAPI.fetchAllPodcasts { (podcasts) -> Void in
            self.podcasts = podcasts
            self.orderedPodcasts = podcasts.sort({ (podcast1, podcast2) -> Bool in
                // is podcast1 ordererd before podcast2
                return podcast1.name < podcast2.name
            })
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            })
        }
    }
    
    deinit {
        // fixes https://github.com/funkenstrahlen/Listen/issues/36
        resultSearchController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refresh(sender: AnyObject) {
        refreshControl?.endRefreshing()
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
        
        // set the datasource depending on the current state
        // if the user is searching use the filtered array
        let dataSource: [Podcast]
        if resultSearchController.active {
            dataSource = filteredPodcasts
        } else {
            dataSource = orderedPodcasts
        }
        
        // check if there is data to display, otherwise show the no results cell
        if dataSource.count > 0 {
            if let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell", forIndexPath: indexPath) as? AddFavoriteTableViewCell {
                cell.podcast = dataSource[indexPath.row]
                return cell
            }
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("NoResultsCell", forIndexPath: indexPath)
        return cell
    }
    
    // MARK: search
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filteredPodcasts = self.orderedPodcasts.filter({ (podcast) -> Bool in
            let podcastName = podcast.name.lowercaseString
            let stringMatch = podcastName.rangeOfString(searchText.lowercaseString)
            return stringMatch != nil
        })
    }
    
    /**
        This is called every time the text field content of the search controller changes.
    */
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
            tableView.reloadData()
        }

    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // configure event detail view controller as popup content
        let favoriteDetailVC = storyboard.instantiateViewControllerWithIdentifier("FavoriteDetail") as! FavoriteDetailViewController
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddFavoriteTableViewCell
        favoriteDetailVC.podcast = cell.podcast
        
        let window = UIApplication.sharedApplication().delegate?.window!
        PathDynamicModal.show(modalView: favoriteDetailVC, inView: window!)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    

}
