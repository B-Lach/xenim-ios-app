//
//  FavoriteDetailViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class PodcastDetailViewController: UIViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    var podcast: Podcast!
    
    var dismissHandler: (() -> Void)?
    
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastDescriptionTextView: UITextView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = podcast.artwork.originalUrl{
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        
        podcastDescriptionTextView.text = podcast.podcastDescription
        
        setupToolbar()
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewDidLayoutSubviews() {
        // ensure text view is scrolled to the top
        podcastDescriptionTextView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
        //eventDescriptionTextView.setContentOffset(CGPointZero, animated: false)
        //eventDescriptionTextView.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        // scale the popover
        view.layer.cornerRadius = 10.0
        view.bounds = CGRectMake(0, 0, screenSize.width * 0.8, screenSize.height * 0.75)
    }
    
    func setupToolbar() {
        var items = [UIBarButtonItem]()
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        if podcast.websiteUrl != nil {
            let websiteBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-safari"), style: .Plain, target: self, action: "openWebsite")
            items.append(websiteBarButton)
            items.append(space)
        }
        
        if podcast.twitterURL != nil {
            let twitterBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-twitter-square"), style: .Plain, target: self, action: "openTwitter")
            items.append(twitterBarButton)
            items.append(space)
        }
        
        if podcast.feedUrl != nil {
            let subscribeBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-rss-square"), style: .Plain, target: self, action: "subscribe")
            items.append(subscribeBarButton)
            items.append(space)
        }
        
        if podcast.email != nil {
            let mailBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-envelope"), style: .Plain, target: self, action: "sendMail")
            items.append(mailBarButton)
            items.append(space)
        }
        
        // more
        
        // last item should not be a space, so remove it then
        if items.last == space {
            items.removeLast()
        }
        
        toolbar.setItems(items, animated: true)
    }
    
    // MARK: - Actions
    
    func openWebsite() {
        let svc = SFSafariViewController(URL: podcast.websiteUrl!)
        svc.delegate = self
        UIApplication.sharedApplication().statusBarStyle = .Default
        self.presentViewController(svc, animated: true, completion: nil)
    }
    
    func openTwitter() {
        let svc = SFSafariViewController(URL: podcast.twitterURL!)
        svc.delegate = self
        UIApplication.sharedApplication().statusBarStyle = .Default
        self.presentViewController(svc, animated: true, completion: nil)
        
    }
    
    func subscribe() {
        let subscribeClients = podcast.subscribeURLSchemesDictionary!
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
    
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let emailTitle = NSLocalizedString("podcast_detailview_feedback_mail_title", value: "Feedback", comment: "the user can send a feedback mail to the podcast. this is the preset mail title.")
            let messageBody = NSLocalizedString("podcast_detailview_feedback_mail_body", value: "Hello,\n", comment: "mail body for a new feedback mail message")
            let toRecipents = [podcast.email!]
            
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents)
            
            UIApplication.sharedApplication().statusBarStyle = .Default
            
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            // show error message if device is not configured to send mail
            let message = NSLocalizedString("podcast_detailview_mail_not_supported_message", value: "Your device is not setup to send email.", comment: "the message shown to the user in an alert view if his device is not setup to send email")
            showInfoMessage("Info", message: message)
        }
        
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: podcast.id)
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
    
    // MARK: - static global
    
    // if the info button in the player for a specific event is pressed
    // this table view controller should segue to the event detail view
    static func showPodcastInfo(podcast podcast: Podcast) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // configure event detail view controller as popup content
        let podcastDetailVC = storyboard.instantiateViewControllerWithIdentifier("PodcastDetail") as! PodcastDetailViewController
        podcastDetailVC.podcast = podcast
        
        let window = UIApplication.sharedApplication().delegate?.window!
        let modal = PathDynamicModal.show(modalView: podcastDetailVC, inView: window!)
        
        podcastDetailVC.dismissHandler = {[weak modal] in
            modal?.closeWithStraight()
            return
        }
    }
    
}
