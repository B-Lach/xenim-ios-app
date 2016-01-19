//
//  SettingsTableViewController.swift
//  Xenim
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
    @IBOutlet weak var xenimDonationCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            openWebsite("https://flattr.com/profile/i42n")
        } else if selectedCell == reportBugCell {
            openWebsite("https://github.com/funkenstrahlen/xenim-ios-app/issues/new")
        } else if selectedCell == paypalCell {
            openWebsite("https://paypal.me/stefantrauth")
        } else if selectedCell == xenimDonationCell {
            openWebsite("http://streams.xenim.de/about/#donate")
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func openWebsite(urlString: String) {
        if let url = NSURL(string: urlString) {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func sendMail() {
        // check if the user is able to send mail
        if MFMailComposeViewController.canSendMail() {
            
            let appVersionString = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")!
            let emailTitle = NSLocalizedString("settings_view_mail_title", value: "Listen Support", comment: "mail title for a new support mail message")
            let messageBody = NSLocalizedString("settings_view_mail_body", value: "Please try to explain your problem as detailed as possible, so we can find the best solution for your problem faster.\n\nInstalled Version: \(appVersionString)", comment: "mail body for a new support mail message")
            let toRecipents = ["app-support@funkenstrahlen.de"]
            
            // configure mail compose view controller
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents)
            
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            // show error message if device is not configured to send mail
            let message = NSLocalizedString("settings_view_mail_not_supported_message", value: "Your device is not setup to send email.", comment: "the message shown to the user in an alert view if his device is not setup to send email")
            showInfoMessage("Info", message: message)
        }
    }
    
    /**
        Mail compose view controller delegate method to dismiss if finished and react to errors
    */
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue: break
        case MFMailComposeResultSaved.rawValue: break
        case MFMailComposeResultSent.rawValue: break
        case MFMailComposeResultFailed.rawValue:
            let mailFailureTitle = NSLocalizedString("info_message_mail_sent_failure_message", value: "Mail sent failure", comment: "If the user tried to sent an email and it could not be sent an alert view does show the error message. this is the title of the alert view popup")
            showInfoMessage(mailFailureTitle, message: (error?.localizedDescription)!)
        default:
            break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
