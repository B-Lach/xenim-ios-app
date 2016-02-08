//
//  ChatContainerViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 05/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class ChatContainerViewController: UIViewController, ChatStatusViewDelegate {

    weak var statusBarStyleDelegate: StatusBarDelegate!
    weak var pageViewDelegate: PageViewDelegate!
    
    var event: Event!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.LightContent)
    }
    
    func updateStatusMessage(message: String) {
        statusMessageLabel.hidden = message == ""
        statusMessageLabel.text = message
    }
    
    @IBAction func accountPressed(sender: AnyObject) {
        // TODO
    }

    @IBAction func backToPlayer(sender: AnyObject) {
        pageViewDelegate.showPage(1)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "EmbedChatTextViewController":
                if let destVC = segue.destinationViewController as? ChatTextViewController {
                    destVC.event = event
                    destVC.statusViewDelegate = self
                }
            default: break
            }
        }
    }
    

}
