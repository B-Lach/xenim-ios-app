//
//  ChatTextViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import SlackTextViewController
import XMPPFramework

struct Message {
    var sender: String
    var text: String
    var date: NSDate
}

protocol ChatStatusViewDelegate: class {
    func updateStatusMessage(message: String)
}

class ChatTextViewController: SLKTextViewController, XMPPStreamDelegate, XMPPRoomDelegate {
    
    var messages = [Message]()
    var event: Event!
    
    
    weak var statusViewDelegate: ChatStatusViewDelegate!
    
    var channel: String {
        get {
            return event.podcast.ircChannel!
        }
    }
    let nickname = "ios-irc-test"
    let realname = "Test"
    var xmppStream: XMPPStream!
    var xmppRoom: XMPPRoom!
    
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
        statusViewDelegate.updateStatusMessage("Connecting")
        self.setTextInputbarHidden(true, animated: false)
        
        self.rightButton.tintColor = Constants.Colors.tintColor
        
        connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        print("disconnecting")
        disconnect()
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

        cell.nickname = nickname
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
            let xmppMessage = XMPPMessage(type: "chat")
            xmppMessage.addBody(textView.text)
            xmppRoom.sendMessage(xmppMessage)
            textView.text = ""
        }
    }
    
    private func addNewMessage(message: Message) {
        tableView.beginUpdates()
        messages.append(message)
        let indexPath = NSIndexPath(forRow: messages.count - 1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        tableView.endUpdates()
        tableView.scrollToBottom(false)
    }
    
    // MARK: XMPP Stream Delegate
    
    func connect() {
        // setup the stream
        xmppStream = XMPPStream()
        xmppStream.myJID = XMPPJID.jidWithString("funkenstrahlen@xmpp.stefantrauth.de")
        xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())

        // setting up plugins
        let xmppReconnect = XMPPReconnect()
        xmppReconnect.activate(xmppStream)
        
        // connecting
        do {
            print("connecting")
            try xmppStream.connectWithTimeout(10)
        } catch {
            print("connection error")
//            statusViewDelegate.updateStatusMessage("No Chat")
        }
    }
    
    func disconnect() {
        xmppStream.disconnect()
    }
    
    func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        print("error sending message: \(error)")
    }
    
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("could not authenticate \(error)")
    }
    
    func xmppStream(sender: XMPPStream!, didNotRegister error: DDXMLElement!) {
        print("could not register \(error)")
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("authenticated successfully")
        xmppRoom = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: XMPPJID.jidWithString("freakshow@conference.xmpp.stefantrauth.de"), dispatchQueue: dispatch_get_main_queue())
        xmppRoom.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        xmppRoom.activate(xmppStream)
        xmppRoom.joinRoomUsingNickname(nickname, history: nil)
    }
    
    func xmppStreamDidRegister(sender: XMPPStream!) {
        print("registered successfully")
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
        print("did connect")
        // register if not registered
//        xmppStream.registerWithPassword("")
        // else authenticate
        
        do {
            print("authenticating")
            try xmppStream.authenticateWithPassword("password")
        } catch {
            print("error authenticating")
        }
    }
    
    func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        print("disconnected due to \(error)")
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("received error \(error)")
    }
    
    func xmppStreamConnectDidTimeout(sender: XMPPStream!) {
        print("timeout")
    }
    
    func xmppStreamDidSecure(sender: XMPPStream!) {
        print("secured stream")
    }
    
    // MARK: - XMPP Room Delegate
    
    func xmppRoom(sender: XMPPRoom!, didReceiveMessage message: XMPPMessage!, fromOccupant occupantJID: XMPPJID!) {
        print("\(message.fromStr()): \(message.body())")
        let message = Message(sender: message.from().user, text: message.body(), date: NSDate())
        addNewMessage(message)
    }
    
    func xmppRoomDidCreate(sender: XMPPRoom!) {
        xmppRoom.configureRoomUsingOptions(nil) // nil to accept default configuration
        print("created room \(sender.roomJID.bare())")
    }
    
    func xmppRoomDidJoin(sender: XMPPRoom!) {
        print("joined room \(sender.roomJID.bare())")
        statusViewDelegate.updateStatusMessage("")
        self.setTextInputbarHidden(false, animated: true)
    }
    
    
    /*
    
    func disconnect() {
        socket.close()
    }
    
    func didWelcome() {
        print("Received welcome message - ready to join a chat room")
        irc.join(channel)
    }
    
    func didJoin(channel: String) {
        print("Joined chat room: \(channel)")
        statusViewDelegate.updateStatusMessage("")
        self.setTextInputbarHidden(false, animated: true)
    }
    
    func didReceivePrivateMessage(text: String, from: String) {
        let message = Message(sender: from, text: text, date: NSDate())
        addNewMessage(message)
    } */
    
}

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRowsInSection(sections - 1)
        self.scrollToRowAtIndexPath(NSIndexPath(forRow: rows - 1, inSection: sections - 1), atScrollPosition: .Bottom, animated: animated)
    }
}