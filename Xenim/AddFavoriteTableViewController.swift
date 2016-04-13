//
//  AddFavoriteTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 26/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class AddFavoriteTableViewController: UITableViewController, UISearchResultsUpdating {
    
    enum State {
        case LOADING
        case SHOW
    }
    
    var state: State = .LOADING

    // contains all podcasts with slug:title
    var podcasts = [Podcast]()
    // contains podcast slugs filtered by search term
    var filteredPodcasts = [Podcast]()
    // contains all podcast slugs ordered alphabetically
    var orderedPodcasts = [Podcast]()
    var resultSearchController: UISearchController!
    
    var messageVC: MessageViewController?
    var loadingVC: UIViewController?
    
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
        loadingVC = storyboard?.instantiateViewControllerWithIdentifier("LoadingViewController")
        messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController
        messageVC?.message = NSLocalizedString("add_favorites_tableview_no_data_message", value: "Could not find something", comment: "this message gets displayed if add favorites table view controller does not have any item to display")
        
        updateBackground()
        
        XenimAPI.fetchAllPodcasts { (podcasts) -> Void in
            self.podcasts = podcasts
            self.orderedPodcasts = podcasts.sort()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.state = .SHOW
                self.updateBackground()
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
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
    
    func updateBackground() {
        if state == .LOADING {
            tableView.backgroundView = loadingVC?.view
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        } else if state == .SHOW {
            var elementCount = 0
            if resultSearchController.active {
                elementCount = filteredPodcasts.count
            } else {
                elementCount = orderedPodcasts.count
            }
            
            if elementCount == 0 {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.None
                tableView.backgroundView = messageVC?.view
            } else {
                tableView.backgroundView = nil
                tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.active {
            return filteredPodcasts.count
        }
        return orderedPodcasts.count
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
        

        let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteCell", forIndexPath: indexPath) as! AddFavoriteTableViewCell
        cell.podcast = dataSource[indexPath.row]
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
            self.tableView.reloadData()
            self.updateBackground()
        }

    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddFavoriteTableViewCell
        let podcast = cell.podcast
        self.performSegueWithIdentifier("podcastDetail", sender: podcast)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destVC = segue.destinationViewController as? PodcastDetailTableViewController {
            if let podcast = sender as? Podcast {
                destVC.podcast = podcast
            }
        }
    }

}
