//
//  FavoritesCollectionViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 06/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

private let reuseIdentifier = "FavoriteCell"

class FavoritesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    // contains the podcast slugs of all favorites
    var favorites = [Podcast]()
    var messageVC: MessageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged"), name: "favoritesChanged", object: nil)
        
        // attach long press gesture to collectionView
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        // add background view to display error message if no data is available to display
        if let messageVC = storyboard?.instantiateViewControllerWithIdentifier("MessageViewController") as? MessageViewController {
            self.messageVC = messageVC
            collectionView?.backgroundView = messageVC.view
        }
        
        // increase content inset for audio player
        collectionView?.contentInset.bottom = collectionView!.contentInset.bottom + 40
        
        refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        updateBackground()
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favorites.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FavoriteCollectionViewCell
        
        // Configure the cell
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
                self.collectionView?.reloadData()
            })
        })
    }

    func updateBackground() {
        if favorites.count == 0 {
            messageVC?.messageLabel.text = NSLocalizedString("favorites_tableview_empty_message", value: "Add podcast shows as your favorite to see them here.", comment: "this message is displayed if no podcast has been added as a favorite and the favorites table view is empty.")
            collectionView?.backgroundView?.hidden = false
        } else {
            collectionView?.backgroundView?.hidden = true
        }
    }
    
    func handleLongPress(lpgr: UILongPressGestureRecognizer) {
        // do not trigger on release
        if lpgr.state == UIGestureRecognizerState.Ended {
            return
        }
        // prevent multiple triggers of the action sheet
        if self.presentedViewController is UIAlertController {
            return
        }
        let point = lpgr.locationInView(self.collectionView!)
        if let indexPath = self.collectionView?.indexPathForItemAtPoint(point) {
            let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! FavoriteCollectionViewCell
            
            let alert = UIAlertController(title: cell.podcast?.name, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.view.tintColor = Constants.Colors.tintColor
            let removeFavorite = NSLocalizedString("favorites_controller_actionsheet_remove_favorite", value: "Remove from Favorites", comment: "If the user does a long press on a favorite an action sheets pops up to remove that podcast from favorites. This is the action sheet action title.")
            alert.addAction(UIAlertAction(title: removeFavorite, style: UIAlertActionStyle.Destructive, handler: { (_) -> Void in
                Favorites.remove(podcastId: cell.podcast!.id)
            }))
            let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel")
            alert.addAction(UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    // MARK: - Layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // define the size of the cells according to the number of columns
        // column count is different for each device category
        if UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.Portrait {
            let columns: CGFloat = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 5.0 : 3.0
            
            let width = self.view.bounds.width / columns
            
            return CGSizeMake(width, width)
        }
        else {
            let columns: CGFloat = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 7.0 : 5.0
            
            let width = self.view.bounds.width / columns
            
            return CGSizeMake(width, width)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
