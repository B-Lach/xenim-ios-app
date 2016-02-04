//
//  ChatTextViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import SlackTextViewController
import GMIRCClient

struct Message {
    var sender: String
    var text: String
    var date: NSDate
}

class ChatTextViewController: SLKTextViewController, GMIRCClientDelegate {
    
    var messages = [Message]()
    var irc: GMIRCClient!
    let channel = "#xsn-irctest"
    let nickname = "ios-irc-test"
    let realname = "Test"
    
    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.Plain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.inverted = false // disable inverted mode
        tableView.separatorColor = UIColor.clearColor()
        
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.registerNib(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "MessageTableViewCell")
        
        let socket = GMSocket(host: "irc.freenode.net", port: 6667)
        irc = GMIRCClient(socket: socket)
        irc.delegate = self
        irc.register(nickname, user: nickname, realName: realname)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageTableViewCell", forIndexPath: indexPath) as! MessageTableViewCell
        
        cell.message = messages[indexPath.row]
    
        return cell
    }
    
    // MARK: - Text View Delegate
    
    override func didPressRightButton(sender: AnyObject!) {
        if textView.text != nil && textView.text != "" {
            // send message
            self.textView.refreshFirstResponder()
            let message = Message(sender: "funkenstrahlen", text: textView.text, date: NSDate())
            irc.sendMessageToChannel(message.text, channel: channel)
            textView.text = ""
            addNewMessage(message)
        }
    }
    
    private func addNewMessage(message: Message) {
        tableView.beginUpdates()
        messages.append(message)
        let indexPath = NSIndexPath(forRow: messages.count - 1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        tableView.endUpdates()
        tableView.scrollToBottom(false)
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: IRC Delegate
    
    func didWelcome() {
        print("Received welcome message - ready to join a chat room")
        irc.join(channel)
    }
    
    func didJoin(channel: String) {
        print("Joined chat room: \(channel)")
    }
    
    func didReceivePrivateMessage(text: String, from: String) {
        let message = Message(sender: from, text: text, date: NSDate())
        addNewMessage(message)
    }
    
}

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRowsInSection(sections - 1)
        self.scrollToRowAtIndexPath(NSIndexPath(forRow: rows - 1, inSection: sections - 1), atScrollPosition: .Bottom, animated: animated)
    }
}