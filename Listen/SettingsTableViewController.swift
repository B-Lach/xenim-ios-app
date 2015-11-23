//
//  SettingsTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 23/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class SettingsTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var contactCell: UITableViewCell!
    @IBOutlet weak var flattrCell: UITableViewCell!
    @IBOutlet weak var reportBugCell: UITableViewCell!
    @IBOutlet weak var paypalCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        if selectedCell == contactCell {
            sendMail()
        } else if selectedCell == flattrCell {
            let svc = SFSafariViewController(URL: NSURL(string: "https://www.flattr.com")!)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        } else if selectedCell == reportBugCell {
            let svc = SFSafariViewController(URL: NSURL(string: "https://www.github.com")!)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        } else if selectedCell == paypalCell {
            let svc = SFSafariViewController(URL: NSURL(string: "https://www.paypal.com")!)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sendMail() {
        let emailTitle = "Test Email"
        let messageBody = "This is a test email body"
        let toRecipents = ["app@funkenstrahlen.de"]
        
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients(toRecipents)
        
        self.presentViewController(mc, animated: true, completion: nil)
    }
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResultSaved.rawValue:
            print("Mail saved")
        case MFMailComposeResultSent.rawValue:
            print("Mail sent")
        case MFMailComposeResultFailed.rawValue:
            print("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
