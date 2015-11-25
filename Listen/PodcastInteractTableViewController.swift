//
//  PodcastInteractTableViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 25/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class PodcastInteractTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    var podcast: Podcast?

    @IBOutlet weak var openWebsiteCell: UITableViewCell!
    @IBOutlet weak var sendMailCell: UITableViewCell!
    @IBOutlet weak var flattrCell: UITableViewCell!
    @IBOutlet weak var subscribeCell: UITableViewCell!
    @IBOutlet weak var twitterCell: UITableViewCell!
    @IBOutlet weak var chatCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func openPodcastWebsite() {
        if let podcast = podcast {
            let svc = SFSafariViewController(URL: podcast.url)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func openTwitter() {
        if let podcast = podcast, let url = podcast.twitterURL {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func openFlattr() {
        if let podcast = podcast, let url = podcast.flattrURL {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
    
    func openChat() {
        if let podcast = podcast, let chatUrl = podcast.chatUrl, let webchatUrl = podcast.webchatUrl {
            if UIApplication.sharedApplication().canOpenURL(chatUrl) {
                // open associated app
                UIApplication.sharedApplication().openURL(chatUrl)
            } else {
                // open webchat in safari
                UIApplication.sharedApplication().openURL(webchatUrl)
            }
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func subscribePodcast() {
        if let podcast = self.podcast {
            let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("podcast_detailview_subscribe_alert_message", value: "Choose Podcast Client", comment: "when the user clicks on the podcast subscribe button an alert view opens to choose a podcast client. this is the message of the alert view."), preferredStyle: .ActionSheet)
            
            // create one option for each podcast client
            for client in podcast.subscribeClients {
                let clientName = client.0
                let subscribeURL = client.1
                
                // only show the option if the podcast client is installed which reacts to this URL
                if UIApplication.sharedApplication().canOpenURL(subscribeURL) {
                    let action = UIAlertAction(title: clientName, style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                        UIApplication.sharedApplication().openURL(subscribeURL)
                    })
                    optionMenu.addAction(action)
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "cancel string"), style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    func sendMailToPodcast() {
        if let podcast = podcast, let email = podcast.email {
            if MFMailComposeViewController.canSendMail() {
                let emailTitle = NSLocalizedString("podcast_detailview_feedback_mail_title", value: "Feedback", comment: "the user can send a feedback mail to the podcast. this is the preset mail title.")
                let messageBody = NSLocalizedString("podcast_detailview_feedback_mail_body", value: "", comment: "mail body for a new feedback mail message")
                let toRecipents = [email]
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                mc.mailComposeDelegate = self
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBody, isHTML: false)
                mc.setToRecipients(toRecipents)
                
                self.presentViewController(mc, animated: true, completion: nil)
            } else {
                // show error message if device is not configured to send mail
                let message = NSLocalizedString("podcast_detailview_mail_not_supported_message", value: "Your device is not setup to send email.", comment: "the message shown to the user in an alert view if his device is not setup to send email")
                showInfoMessage("Info", message: message)
            }
        }
    }
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue: break
        case MFMailComposeResultSaved.rawValue: break
        case MFMailComposeResultSent.rawValue: break
        case MFMailComposeResultFailed.rawValue:
            showInfoMessage("Mail sent failure", message: (error?.localizedDescription)!)
        default:
            break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell == openWebsiteCell {
            openPodcastWebsite()
        } else if cell == subscribeCell {
            subscribePodcast()
        } else if cell == twitterCell {
            openTwitter()
        } else if cell == sendMailCell {
            sendMailToPodcast()
        } else if cell == flattrCell {
            openFlattr()
        } else if cell == chatCell {
            openChat()
        }
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
