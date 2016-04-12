//
//  PodcastDetailViewControllerTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 11/04/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastDetailTableViewController: UITableViewController {

    @IBOutlet weak var coverartImageView: UIImageView!
    var podcast: Podcast!
    
    var gradient: UIGradientView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = podcast.artwork.originalUrl {
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        title = podcast.name
        
        // resize table header view to 1:1 aspect ratio
        // this is not possible with autolayout contraints
        // disable adjust scrollview insets to make this work as expected
        let width = tableView.frame.width
        tableView.tableHeaderView?.frame = CGRectMake(0, 0, width, width)
        
        // adjust bottom insets as auto adjust scrollview insets is disabled
        tableView.contentInset.bottom = tabBarController!.tabBar.bounds.height
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let navbar = self.navigationController?.navigationBar {
            navbar.shadowImage = UIImage() // removes tiny gray line at the bottom of the navigation bar
            navbar.setBackgroundImage(UIImage(), forBarMetrics: .Default) // clear background
            
            let statusbarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
            let navbarHeight = navbar.bounds.height + 2 * statusbarHeight
            // configure gradient view
            gradient = UIGradientView(frame: CGRect(x: 0, y: -statusbarHeight, width: navbar.bounds.width, height: navbarHeight))
            gradient!.userInteractionEnabled = false
            navbar.insertSubview(gradient!, atIndex: 0)
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        updateNavbar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        gradient?.removeFromSuperview()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        updateNavbar()
    }
    
    func updateNavbar() {
        if let navbar = self.navigationController?.navigationBar, let gradient = gradient {
            
            // y pixel count defining how long the clear->color transition is
            let transitionArea: CGFloat = 64
            // where should the transition start
            let navbarChangePoint: CGFloat = coverartImageView.frame.height - transitionArea - gradient.frame.height
            
            // current scrollview y offset
            let offsetY = tableView.contentOffset.y
            if offsetY > navbarChangePoint {
                // transition state + full colored state
                
                let alpha = min(1, 1 - ((navbarChangePoint + transitionArea - offsetY) / transitionArea)) // will become 1
                let inverseAlpha = 1 - alpha // will become 0
                
                // update gradient colors
                gradient.bottomColor = Constants.Colors.tintColor.colorWithAlphaComponent(alpha)
                gradient.topColor = UIColor(red: 0.98 - inverseAlpha, green: 0.19 - inverseAlpha, blue: 0.31 - inverseAlpha, alpha: 1.00)
            } else {
                // transparent state
                gradient.topColor = UIColor.blackColor()
                gradient.bottomColor = UIColor.clearColor()
            }
            
            gradient.setNeedsDisplay()
        }
    }
    
    // MARK: - Table view data source
//
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
