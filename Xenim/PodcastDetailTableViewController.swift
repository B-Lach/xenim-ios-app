//
//  PodcastDetailViewControllerTableViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 11/04/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class PodcastDetailTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    private weak var headerView: UIView!
    @IBOutlet weak var coverartImageView: UIImageView!
    private var headerHeight: CGFloat!

    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var subscribeCell: UITableViewCell!
    @IBOutlet weak var sendMailCell: UITableViewCell!
    @IBOutlet weak var twitterCell: UITableViewCell!
    @IBOutlet weak var websiteCell: UITableViewCell!
    
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    var podcast: Podcast!
    
    var gradient: UIGradientView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coverartImageView.accessibilityLabel = "Coverart image"
        
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = podcast.artwork.originalUrl {
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        title = podcast.name
        descriptionLabel.text = podcast.podcastDescription
        
        // resize table header view to 1:1 aspect ratio
        // this is not possible with autolayout contraints
        // disable adjust scrollview insets to make this work as expected
        headerView = tableView.tableHeaderView
        headerHeight = tableView.frame.width
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
        updateHeaderView()
        
        // adjust bottom insets as auto adjust scrollview insets is disabled
        if let bottomInset = tabBarController?.tabBar.bounds.height {
            tableView.contentInset.bottom = bottomInset + 44 // 44 are for the player popup above the tabbar
        }
        
        // auto cell height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 240 // Something reasonable to help ios render your cells
        
        // disable cells if they have not enough data provided to work
        if podcast.websiteUrl == nil {
            disableCell(websiteCell)
        }
        if podcast.twitterURL == nil {
            disableCell(twitterCell)
        }
        if podcast.email == nil {
            disableCell(sendMailCell)
        }
        if podcast.feedUrl == nil {
            disableCell(subscribeCell)
        }
        
        setupNotifications()
        
        favoriteBarButtonItem.accessibilityLabel = " "
        favoriteBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_favorite_button_hint", value: "double tap to toggle favorite", comment: "") 
        if !Favorites.isFavorite(podcast.id) {
            favoriteBarButtonItem.image = UIImage(named: "star_o_25")
            favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
        } else {
            favoriteBarButtonItem.image = UIImage(named: "star_25")
            favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
        }

    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -headerHeight, width: tableView.bounds.width, height: headerHeight)
        if tableView.contentOffset.y < -headerHeight {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
        }
        
        headerView.frame = headerRect
    }
    
    private func disableCell(cell: UITableViewCell) {
        cell.userInteractionEnabled = false
        cell.textLabel?.enabled = false
        cell.detailTextLabel?.enabled = false
        cell.tintColor = UIColor.lightGrayColor()
        cell.accessoryType = UITableViewCellAccessoryType.None
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
        updateHeaderView()
    }
    
    func updateNavbar() {
        if let gradient = gradient {
            
            // y pixel count defining how long the clear->color transition is
            let transitionArea: CGFloat = 64
            // where should the transition start
            let navbarChangePoint: CGFloat = coverartImageView.frame.height - transitionArea - gradient.frame.height
            
            // current scrollview y offset
            let offsetY = tableView.contentOffset.y + headerHeight
            if offsetY > navbarChangePoint {
                // transition state + full colored state
                
                let alpha = min(1, 1 - ((navbarChangePoint + transitionArea - offsetY) / transitionArea)) // will become 1
                let inverseAlpha = 1 - alpha // will become 0
                
                // update gradient colors
                gradient.bottomColor = Constants.Colors.tintColor.colorWithAlphaComponent(alpha)
                gradient.topColor = UIColor(red: 0.98 - inverseAlpha, green: 0.19 - inverseAlpha, blue: 0.31 - inverseAlpha, alpha: 1.00)
            } else {
                // transparent state
                gradient.topColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
                gradient.bottomColor = UIColor.clearColor()
            }
            
            gradient.setNeedsDisplay()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    // MARK: - Actions
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell == websiteCell {
            openWebsite()
        } else if cell == twitterCell {
            openTwitter()
        } else if cell == sendMailCell {
            sendMail()
        } else if cell == subscribeCell {
            subscribe()
        }
        cell?.setSelected(false, animated: true)
    }
    
    func openWebsite() {
        let svc = SFSafariViewController(URL: podcast.websiteUrl!)
        svc.delegate = self
        self.presentViewController(svc, animated: true, completion: nil)
    }
    
    func openTwitter() {
        let svc = SFSafariViewController(URL: podcast.twitterURL!)
        svc.delegate = self
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
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "Cancel"), style: .Cancel, handler: {
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
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PodcastDetailTableViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PodcastDetailTableViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteBarButtonItem.image = UIImage(named: "star_25")
                favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteBarButtonItem.image = UIImage(named: "star_o_25")
                favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            }
        }
    }
    

}
