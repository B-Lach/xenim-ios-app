//
//  PodcastInteractTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 25/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI


/**
    This is a table view which provides a number of actions for a podcast in detail view.
    For example subscribe to the podcast, open its website, send feedback, ...
*/
class PodcastInteractTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    var podcast: Podcast? {
        didSet {
            hideUnavailableActions()
        }
    }

    @IBOutlet weak var openWebsiteCell: UITableViewCell!
    @IBOutlet weak var sendMailCell: UITableViewCell!
    @IBOutlet weak var flattrCell: UITableViewCell!
    @IBOutlet weak var subscribeCell: UITableViewCell!
    @IBOutlet weak var twitterCell: UITableViewCell!
    @IBOutlet weak var chatCell: UITableViewCell!
    
    // MARK: - init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsetsMake(0, -6, 0, 0)
        hideUnavailableActions()
    }
    
    // MARK: - Update UI
    
    func hideUnavailableActions() {
        if let podcast = podcast {
            if podcast.flattrURL == nil {
                flattrCell?.textLabel?.textColor = UIColor.grayColor()
                flattrCell?.detailTextLabel?.textColor = UIColor.grayColor()
                flattrCell?.imageView?.image = UIImage(named: "steel-25-heart")
            }
            if podcast.webchatUrl == nil {
                chatCell?.textLabel?.textColor = UIColor.grayColor()
                chatCell?.detailTextLabel?.textColor = UIColor.grayColor()
                chatCell?.imageView?.image = UIImage(named: "steel-25-comments")
            }
            if podcast.twitterURL == nil {
                twitterCell?.textLabel?.textColor = UIColor.grayColor()
                twitterCell?.detailTextLabel?.textColor = UIColor.grayColor()
                twitterCell?.imageView?.image = UIImage(named: "steel-25-twitter-square")
            }
            if podcast.email == nil {
                sendMailCell?.textLabel?.textColor = UIColor.grayColor()
                sendMailCell?.detailTextLabel?.textColor = UIColor.grayColor()
                sendMailCell?.imageView?.image = UIImage(named: "steel-25-envelope")
            }
            if podcast.websiteUrl == nil {
                openWebsiteCell?.textLabel?.textColor = UIColor.grayColor()
                openWebsiteCell?.detailTextLabel?.textColor = UIColor.grayColor()
                openWebsiteCell?.imageView?.image = UIImage(named: "steel-25-safari")
            }
            if podcast.feedUrl == nil {
                subscribeCell?.textLabel?.textColor = UIColor.grayColor()
                subscribeCell?.detailTextLabel?.textColor = UIColor.grayColor()
                subscribeCell?.imageView?.image = UIImage(named: "steel-25-rss-square")
            }
        }
    }
    
    // MARK: - Actions
    
    func openPodcastWebsite() {
        if let podcast = podcast, let url = podcast.websiteUrl {
            print(url)
            let svc = SFSafariViewController(URL: url)
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
        if let podcast = podcast, let ircUrl = podcast.ircUrl, let webchatUrl = podcast.webchatUrl {
            if UIApplication.sharedApplication().canOpenURL(ircUrl) {
                // open associated app
                UIApplication.sharedApplication().openURL(ircUrl)
            } else {
                // open webchat in safari
                UIApplication.sharedApplication().openURL(webchatUrl)
            }
        }
    }
    
    func subscribePodcast() {
        if let podcast = self.podcast, let subscribeClients = podcast.subscribeURLSchemesDictionary {
            let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("podcast_detailview_subscribe_alert_message", value: "Choose Podcast Client", comment: "when the user clicks on the podcast subscribe button an alert view opens to choose a podcast client. this is the message of the alert view."), preferredStyle: .ActionSheet)
            optionMenu.view.tintColor = Constants.Colors.tintColor
            
            // create one option for each podcast client
            for client in subscribeClients {
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
                let messageBody = NSLocalizedString("podcast_detailview_feedback_mail_body", value: "Hello,\n", comment: "mail body for a new feedback mail message")
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
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - delegate
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
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
    
    // MARK: Popover
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // prevent popover presentation style adaption on iphone, so it is not presented as a modal instead of a popover
        return UIModalPresentationStyle.None
    }
    
    // MARK: Table View
    
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

    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // do not allow segue to show nextup events popover if there is not podcast slug information available
        if identifier == "ShowNextupEvents" && podcast == nil {
            return false
        }
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let cell = sender as? UITableViewCell {
            if segue.identifier == "ShowNextupEvents" {
                if let nextupEventsTableViewController = segue.destinationViewController as? NextupEventsTableViewController {
                    if let popupController = nextupEventsTableViewController.popoverPresentationController {
                        popupController.delegate = self
                        popupController.permittedArrowDirections = [.Down, .Up]
                        popupController.sourceRect = cell.textLabel!.frame
                    }
                    nextupEventsTableViewController.podcastId = podcast?.id
                }
            }
        }
    }

}
