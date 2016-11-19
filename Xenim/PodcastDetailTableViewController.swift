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
import XenimAPI

class PodcastDetailTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var coverartImageView: UIImageView!

    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var subscribeCell: UITableViewCell!
    @IBOutlet weak var sendMailCell: UITableViewCell!
    @IBOutlet weak var twitterCell: UITableViewCell!
    @IBOutlet weak var websiteCell: UITableViewCell!
    
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    var podcast: Podcast?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // auto cell height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 240 // Something reasonable to help ios render your cells
        
        tableView.contentInset.top = tableView.contentInset.top - 44
        
        // disable cells if they have not enough data provided to work
        if podcast?.websiteUrl == nil {
            disableCell(websiteCell)
        }
        if podcast?.twitterURL == nil {
            disableCell(twitterCell)
        }
        if podcast?.email == nil {
            disableCell(sendMailCell)
        }
        if podcast?.feedUrl == nil {
            disableCell(subscribeCell)
        }
        
        if let podcast = podcast {
            coverartImageView.accessibilityLabel = "Coverart image"
            
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                if let imageurl = podcast.artwork.thumb800Url {
                    coverartImageView.af_setImage(withURL: imageurl, placeholderImage: nil, imageTransition: .crossDissolve(0.2))
                }
            case .pad:
                if let imageurl = podcast.artwork.thumb1600Url {
                    coverartImageView.af_setImage(withURL: imageurl, placeholderImage: nil, imageTransition: .crossDissolve(0.2))
                }
            default: break
            }

            title = podcast.name
            descriptionLabel.text = podcast.podcastDescription
            
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
    }
    
    private func disableCell(_ cell: UITableViewCell) {
        cell.isUserInteractionEnabled = false
        cell.textLabel?.isEnabled = false
        cell.detailTextLabel?.isEnabled = false
        cell.tintColor = UIColor.lightGray
        cell.accessoryType = UITableViewCellAccessoryType.none
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Actions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
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
        if let podcast = podcast {
            let svc = SFSafariViewController(url: podcast.websiteUrl! as URL)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    func openTwitter() {
        if let podcast = podcast {
            let svc = SFSafariViewController(url: podcast.twitterURL! as URL)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    func subscribe() {
        if let podcast = podcast {
            let subscribeClients = podcast.subscribeURLSchemesDictionary!
            let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("podcast_detailview_subscribe_alert_message", value: "Choose Podcast Client", comment: "when the user clicks on the podcast subscribe button an alert view opens to choose a podcast client. this is the message of the alert view."), preferredStyle: .actionSheet)
            optionMenu.view.tintColor = Constants.Colors.tintColor
            
            // create one option for each podcast client
            for client in subscribeClients {
                let clientName = client.0
                let subscribeURL = client.1
                
                // only show the option if the podcast client is installed which reacts to this URL
                if UIApplication.shared.canOpenURL(subscribeURL as URL) {
                    let action = UIAlertAction(title: clientName, style: .default, handler: { (alert: UIAlertAction!) -> Void in
                        UIApplication.shared.open(subscribeURL as URL, options: [:], completionHandler: nil)
                    })
                    optionMenu.addAction(action)
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "Cancel"), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(cancelAction)
            
            optionMenu.popoverPresentationController?.sourceView = subscribeCell
            
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    func sendMail() {
        if let podcast = podcast {
            if MFMailComposeViewController.canSendMail() {
                let emailTitle = NSLocalizedString("podcast_detailview_feedback_mail_title", value: "Feedback", comment: "the user can send a feedback mail to the podcast. this is the preset mail title.")
                let messageBody = NSLocalizedString("podcast_detailview_feedback_mail_body", value: "Hello,\n", comment: "mail body for a new feedback mail message")
                let toRecipents = [podcast.email!]
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                mc.mailComposeDelegate = self
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBody, isHTML: false)
                mc.setToRecipients(toRecipents)
                
                self.present(mc, animated: true, completion: nil)
            } else {
                // show error message if device is not configured to send mail
                let message = NSLocalizedString("podcast_detailview_mail_not_supported_message", value: "Your device is not setup to send email.", comment: "the message shown to the user in an alert view if his device is not setup to send email")
                showInfoMessage("Info", message: message)
            }
        }
    }
    
    func showInfoMessage(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func toggleFavorite(_ sender: AnyObject) {
        if let podcast = podcast {
            Favorites.toggle(podcastId: podcast.id)
        }
    }
    
    // MARK: - delegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller:MFMailComposeViewController, didFinishWith result:MFMailComposeResult, error:Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue: break
        case MFMailComposeResult.saved.rawValue: break
        case MFMailComposeResult.sent.rawValue: break
        case MFMailComposeResult.failed.rawValue:
            let mailFailureTitle = NSLocalizedString("info_message_mail_sent_failure_message", value: "Mail sent failure", comment: "If the user tried to sent an email and it could not be sent an alert view does show the error message. this is the title of the alert view popup")
            showInfoMessage(mailFailureTitle, message: (error?.localizedDescription)!)
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(PodcastDetailTableViewController.favoriteAdded(_:)), name: Favorites.favoriteAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PodcastDetailTableViewController.favoriteRemoved(_:)), name: Favorites.favoriteRemovedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func favoriteAdded(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast?.id {
                favoriteBarButtonItem.image = UIImage(named: "star_25")
                favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast?.id {
                favoriteBarButtonItem.image = UIImage(named: "star_o_25")
                favoriteBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            }
        }
    }
    

}
