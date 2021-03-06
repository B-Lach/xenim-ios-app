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
import Parse

class SettingsTableViewController: UITableViewController, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate, SKProductsRequestDelegate {

    @IBOutlet weak var xenimCell: UITableViewCell!
    @IBOutlet weak var contactCell: UITableViewCell!
    @IBOutlet weak var smallDonationCell: UITableViewCell!
    @IBOutlet weak var middleDonationCell: UITableViewCell!
    @IBOutlet weak var bigDonationCell: UITableViewCell!
    @IBOutlet weak var faqCell: UITableViewCell!
    @IBOutlet weak var reviewCell: UITableViewCell!
    @IBOutlet weak var pushTokenCell: UITableViewCell!
    @IBOutlet weak var versionCell: UITableViewCell!
    
    @IBOutlet weak var middleDonationPriceLabel: UILabel!
    @IBOutlet weak var smallDonationPriceLabel: UILabel!
    @IBOutlet weak var bigDonationPriceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // auto cell height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 240 // Something reasonable to help ios render your cells
        versionCell.detailTextLabel?.text = UIApplication.sharedApplication().appVersion()
        pushTokenCell.detailTextLabel?.text = PFInstallation.currentInstallation().deviceToken

        smallDonationCell.accessibilityTraits = UIAccessibilityTraitButton
        middleDonationCell.accessibilityTraits = UIAccessibilityTraitButton
        bigDonationCell.accessibilityTraits = UIAccessibilityTraitButton
        
        fetchIAPPrices()
        
    }
    
    private func fetchIAPPrices() {
        let request = SKProductsRequest(productIdentifiers: ["com.stefantrauth.XenimSupportSmall", "com.stefantrauth.XenimSupportMiddle", "com.stefantrauth.XenimSupportBig"])
        request.delegate = self
        request.start()
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        for product in response.products {

            let formatter = NSNumberFormatter()
            formatter.formatterBehavior = NSNumberFormatterBehavior.Behavior10_4
            formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            formatter.locale = product.priceLocale
            
            switch product.productIdentifier {
            case "com.stefantrauth.XenimSupportSmall":
                smallDonationPriceLabel.text = formatter.stringFromNumber(product.price)
            case "com.stefantrauth.XenimSupportMiddle":
                middleDonationPriceLabel.text = formatter.stringFromNumber(product.price)
            case "com.stefantrauth.XenimSupportBig":
                bigDonationPriceLabel.text = formatter.stringFromNumber(product.price)
            default:
                break
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        if selectedCell == contactCell {
            sendMail()
        } else if selectedCell == faqCell {
            openWebsite("https://xenimapp.stefantrauth.de/support/")
        } else if selectedCell == xenimCell {
            openWebsite("http://streams.xenim.de")
        } else if selectedCell == reviewCell {
            UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/id1073103750")!)
        } else if selectedCell == smallDonationCell {
            PFPurchase.buyProduct("com.stefantrauth.XenimSupportSmall", block: { (error: NSError?) in
                if error != nil {
                    self.showError(error!)
                }
            })
        } else if selectedCell == middleDonationCell {
            PFPurchase.buyProduct("com.stefantrauth.XenimSupportMiddle", block: { (error: NSError?) in
                if error != nil {
                    self.showError(error!)
                }
            })
        } else if selectedCell == bigDonationCell {
            PFPurchase.buyProduct("com.stefantrauth.XenimSupportBig", block: { (error: NSError?) in
                if error != nil {
                    self.showError(error!)
                }
            })
        } else if selectedCell == pushTokenCell {
            UIPasteboard.generalPasteboard().string = pushTokenCell.detailTextLabel?.text
        }
        selectedCell?.setSelected(false, animated: true)
    }
    
    private func showError(error: NSError) {
        print(error.localizedDescription)
        let alertVC = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        let dismissAction = UIAlertAction(title: dismiss, style: .Default, handler: nil)
        alertVC.addAction(dismissAction)
        self.presentViewController(alertVC, animated: true, completion: nil)
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
            
            let appVersionString = UIApplication.sharedApplication().appVersion()!
            let pushToken = pushTokenCell.detailTextLabel?.text
            let installationInformationString = "\(appVersionString), \(pushToken)"
            
            let emailTitle = NSLocalizedString("settings_view_mail_title", value: "Xenim Support", comment: "mail title for a new support mail message")
            let messageBody = String(format: NSLocalizedString("settings_view_mail_body", value: "Please try to explain your problem as detailed as possible, so we can find the best solution for your problem faster.\n\n%@", comment: "mail body for a new support mail message"), installationInformationString)
            let toRecipents = ["xenimapp@stefantrauth.de"]
            
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
