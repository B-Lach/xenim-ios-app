//
//  PodcastInfoViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class PodcastInfoViewController: UIViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    weak var statusBarStyleDelegate: StatusBarDelegate!
    weak var pageViewDelegate: PageViewDelegate!
    
    var event: Event!

    @IBOutlet weak var topbarView: UIView!
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.width / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().CGColor
            coverartImageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.originalUrl {
            coverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        }
        podcastNameLabel?.text = event.podcast.name
        podcastDescriptionLabel?.text = event.podcast.podcastDescription
        eventTitleLabel?.text = event.title
        updateFavoriteButton()
        setupToolbar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.LightContent)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(event.podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
        }
    }
    
    func setupToolbar() {
        var items = [UIBarButtonItem]()
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        items.append(space)
        
        if event.podcast.websiteUrl != nil {
            let websiteBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-safari"), style: .Plain, target: self, action: #selector(PodcastInfoViewController.openWebsite))
            items.append(websiteBarButton)
            items.append(space)
        }
        
        if event.podcast.twitterURL != nil {
            let twitterBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-twitter-square"), style: .Plain, target: self, action: #selector(PodcastInfoViewController.openTwitter))
            items.append(twitterBarButton)
            items.append(space)
        }
        
        if event.podcast.feedUrl != nil {
            let subscribeBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-rss-square"), style: .Plain, target: self, action: #selector(PodcastInfoViewController.subscribe))
            items.append(subscribeBarButton)
            items.append(space)
        }
        
        if event.podcast.email != nil {
            let mailBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-envelope"), style: .Plain, target: self, action: #selector(PodcastInfoViewController.sendMail))
            items.append(mailBarButton)
            items.append(space)
        }
        
        // more
        
        // last item should not be a space, so remove it then
//        if items.last == space {
//            items.removeLast()
//        }
        
        toolbar.setItems(items, animated: true)
        
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func backToPlayer(sender: AnyObject) {
        pageViewDelegate.showPage(0)
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: event.podcast.id)
    }
    
    func openWebsite() {
        let svc = SFSafariViewController(URL: event.podcast.websiteUrl!)
        svc.delegate = self
        self.presentViewController(svc, animated: true, completion: nil)
    }
    
    func openTwitter() {
        let svc = SFSafariViewController(URL: event.podcast.twitterURL!)
        svc.delegate = self
        self.presentViewController(svc, animated: true, completion: nil)
        
    }
    
    func subscribe() {
        let subscribeClients = event.podcast.subscribeURLSchemesDictionary!
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
            let toRecipents = [event.podcast.email!]
            
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
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventDetailViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventDetailViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func animateFavoriteButton() {
        favoriteButton.transform = CGAffineTransformMakeScale(1.3, 1.3)
        UIView.animateWithDuration(0.3,
                                   delay: 0,
                                   usingSpringWithDamping: 2,
                                   initialSpringVelocity: 1.0,
                                   options: [UIViewAnimationOptions.CurveEaseOut],
                                   animations: {
                                    self.favoriteButton.transform = CGAffineTransformIdentity
            }, completion: nil)
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
