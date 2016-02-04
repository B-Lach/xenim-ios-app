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
    
    var socket: GMSocket!
    var irc: GMIRCClient!
    let channel = "#xsn-irctest"
    let nickname = "ios-irc-test"
    let realname = "Test"
    
    var statusBarStyleDelegate: StatusBarDelegate!
    
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
        
        textView.placeholder = "Your Message"
        self.title = "Connecting..."
        self.setTextInputbarHidden(true, animated: false)
        
        connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        disconnect()
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.Default)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MessageTableViewCell
        let username = cell.message.sender
        textView.text = textView.text + "\(username): "
        cell.setSelected(false, animated: true)
    }
    
    // MARK: - Text View Delegate
    
    override func didPressRightButton(sender: AnyObject!) {
        if textView.text != nil && textView.text != "" {
            // send message
            self.textView.refreshFirstResponder()
            let message = Message(sender: nickname, text: textView.text, date: NSDate())
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
    
    // MARK: IRC Delegate
    
    func connect() {
        socket = GMSocket(host: "irc.freenode.net", port: 6667)
        irc = GMIRCClient(socket: socket)
        irc.delegate = self
        irc.register(nickname, user: nickname, realName: realname)
    }
    
    func disconnect() {
        socket.close()
    }
    
    func didWelcome() {
        print("Received welcome message - ready to join a chat room")
        irc.join(channel)
    }
    
    func didJoin(channel: String) {
        print("Joined chat room: \(channel)")
        self.title = channel
        self.setTextInputbarHidden(false, animated: true)
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