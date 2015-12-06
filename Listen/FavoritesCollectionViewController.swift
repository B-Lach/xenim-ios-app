//
//  FavoritesCollectionViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 06/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

private let reuseIdentifier = "FavoriteCell"

class FavoritesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // contains the podcast slugs of all favorites
    var favorites = [String]()
    var messageVC: MessageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.registerClass(FavoriteCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged"), name: "favoritesChanged", object: nil)
        
        // add background view to display error message if no data is available to display
//        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
//            self.messageVC = messageVC
//            collectionView!.backgroundView = messageVC.view
//        }
        
        // increase content inset for audio player
        collectionView!.contentInset.bottom = collectionView!.contentInset.bottom + 40
        
        refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //updateBackground()
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favorites.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FavoriteCollectionViewCell
        
        // Configure the cell
        cell.podcastSlug = favorites[indexPath.row]
        
        return cell
    }
    
    func favoritesChanged() {
        refresh()
    }
    
    func refresh() {
        favorites = Favorites.fetch()
        favorites.sortInPlace()
        collectionView!.reloadData()
    }

//    func updateBackground() {
//        if favorites.count == 0 {
//            messageVC?.messageLabel.text = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
//            collectionView!.backgroundView?.hidden = false
//        } else {
//            collectionView!.backgroundView?.hidden = true
//        }
//    }
    
    // MARK: - Layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.Portrait {
            let columns: CGFloat = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 3.0 : 2.0
            
            let width = CGRectGetWidth(self.view.frame) / columns
            
            return CGSizeMake(width, width)
        }
        else {
            let columns: CGFloat = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 4.0 : 3.0
            
            let width = CGRectGetWidth(self.view.frame) / columns
            
            return CGSizeMake(width, width)
        }
    }
    
    // MARK: - Navigation
    
    // rewind segues
    @IBAction func dismissSettings(segue:UIStoryboardSegue) {}
    @IBAction func dismissAddFavorite(segue:UIStoryboardSegue) {}
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // only allow segue to podcast detail view controller if podcast data for the cell
        // has already been fetched.
        if identifier == "PodcastDetail" {
            if let cell = sender as? FavoriteCollectionViewCell {
                if cell.podcast == nil {
                    return false
                }
            }
        }
        // for all other segues return true by default
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dvc = segue.destinationViewController as? PodcastDetailViewController {
            if segue.identifier == "PodcastDetail" {
                if let cell = sender as? FavoriteCollectionViewCell {
                    if let podcast = cell.podcast {
                        dvc.podcast = podcast
                    }
                }
            }
        }
    }

}
