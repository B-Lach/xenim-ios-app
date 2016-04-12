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
    
    var gradient: UIGradientView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let navbar = self.navigationController?.navigationBar {
            navbar.shadowImage = UIImage()
            navbar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            let statusbarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
            gradient = UIGradientView(frame: CGRect(x: 0, y: -statusbarHeight, width: navbar.bounds.width, height: 2 * (navbar.bounds.height + statusbarHeight)))
            gradient!.userInteractionEnabled = false
            navbar.insertSubview(gradient!, atIndex: 0)
        }

    }
    
    override func viewWillDisappear(animated: Bool) {
//        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if let navController = self.navigationController {
//            let gradient = CAGradientLayer()
//            let bounds = navController.navigationBar.bounds
//            gradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + UIApplication.sharedApplication().statusBarFrame.size.height)
//            
//            let navbarChangePoint: CGFloat = coverartImageView.frame.height - 3 * gradient.frame.height
//            
//            let offsetY = scrollView.contentOffset.y
//            if offsetY > navbarChangePoint {
//                let alpha = min(1, 1 - ((navbarChangePoint + 64 - offsetY) / 64)) // will become 1
//                let inverseAlpha = 1 - alpha // will become 0
//                let bottom = Constants.Colors.tintColor.colorWithAlphaComponent(alpha)
//                let top = UIColor(red: 0.98 - inverseAlpha, green: 0.19 - inverseAlpha, blue: 0.31 - inverseAlpha, alpha: 1.00)
//                gradient.colors = [top.CGColor, bottom.CGColor]
//            } else {
//                gradient.colors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
//            }
//            
//            navController.navigationBar.setBackgroundImage(imageFromLayer(gradient), forBarMetrics: UIBarMetrics.Default)
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
