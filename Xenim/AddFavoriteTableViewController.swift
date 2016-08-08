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
        case loading
        case show
    }
    
    var state: State = .loading

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
        
        self.splitViewController?.preferredDisplayMode = .allVisible

        // add search bar
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        resultSearchController.searchBar.tintColor = Constants.Colors.tintColor
        resultSearchController.hidesNavigationBarDuringPresentation = false

        // fetch podcast list from API
        loadingVC = storyboard?.instantiateViewController(withIdentifier: "LoadingViewController")
        messageVC = storyboard?.instantiateViewController(withIdentifier: "MessageViewController") as? MessageViewController
        messageVC?.message = NSLocalizedString("add_favorites_tableview_no_data_message", value: "Could not find something", comment: "this message gets displayed if add favorites table view controller does not have any item to display")
        
        updateBackground()
        
        XenimAPI.fetchAllPodcasts { (podcasts) -> Void in
            self.podcasts = podcasts
            self.orderedPodcasts = podcasts.sorted()
            DispatchQueue.main.async(execute: { () -> Void in
                self.state = .show
                self.updateBackground()

                self.tableView.tableHeaderView = self.resultSearchController.searchBar
                
                self.tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.fade)
            })
        }
    }
    
    deinit {
        // fixes https://github.com/funkenstrahlen/Listen/issues/36
        resultSearchController.view.removeFromSuperview()
    }
    
    
    func updateBackground() {
        if state == .loading {
            tableView.backgroundView = loadingVC?.view
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        } else if state == .show {
            var elementCount = 0
            if resultSearchController.isActive {
                elementCount = filteredPodcasts.count
            } else {
                elementCount = orderedPodcasts.count
            }
            
            if elementCount == 0 {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.none
                tableView.backgroundView = messageVC?.view
            } else {
                tableView.backgroundView = nil
                tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.isActive {
            return filteredPodcasts.count
        }
        return orderedPodcasts.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // set the datasource depending on the current state
        // if the user is searching use the filtered array
        let dataSource: [Podcast]
        if resultSearchController.isActive {
            dataSource = filteredPodcasts
        } else {
            dataSource = orderedPodcasts
        }
        

        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as! AddFavoriteTableViewCell
        cell.podcast = dataSource[(indexPath as NSIndexPath).row]
        return cell
    }
    
    // MARK: search
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter the array using the filter method
        self.filteredPodcasts = self.orderedPodcasts.filter({ (podcast) -> Bool in
            let podcastName = podcast.name.lowercased()
            let stringMatch = podcastName.range(of: searchText.lowercased())
            return stringMatch != nil
        })
    }
    
    /**
        This is called every time the text field content of the search controller changes.
    */
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
            self.tableView.reloadData()
            self.updateBackground()
        }

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! AddFavoriteTableViewCell
        let podcast = cell.podcast
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        self.performSegue(withIdentifier: "podcastDetail", sender: podcast)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
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

}
