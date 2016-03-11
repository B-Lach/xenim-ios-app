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
    
    var nickname: String?
    var xmppStream: XMPPStream!
    var xmppRoom: XMPPRoom!
    let xmppServer = "xmpp.stefantrauth.de"
    var mucRoomName: String {
        get {
            // make lowercase and strip whitespaces
            let podcastName = self.event.podcast.name.lowercaseString
            return podcastName.stringByReplacingOccurrencesOfString(" ", withString: "")
        }
    }
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let userDefaultsNicknameKey = "nickname"
    
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
    
    // MARK: - Actions
    
    func changeNickname(message: String) {
        if xmppStream.isAuthenticated() {
            let alert = UIAlertController(title: "Choose Nickname", message: message, preferredStyle: .Alert)
            alert.view.tintColor = Constants.Colors.tintColor
            
            alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                textField.text = self.nickname
                textField.addTarget(self, action: "textChanged:", forControlEvents: .EditingChanged)
            })
            
            let chooseAction = UIAlertAction(title: "Choose", style: .Default, handler: { (action) -> Void in
                let textField = alert.textFields![0] as UITextField
                // check if nick was changed
                if self.nickname != textField.text {
                    self.nickname = textField.text
                    self.userDefaults.setObject(self.nickname, forKey: self.userDefaultsNicknameKey)
                    print("updated nickname to \(self.nickname)")
                    
                    // update nickname if room is joined
                    if self.xmppRoom.isJoined {
                        print("changing nickname for room")
                        self.xmppRoom.changeNickname(self.nickname)
                    } else {
                        self.xmppRoom.joinRoomUsingNickname(self.nickname, history: nil)
                    }
                }
            })
            chooseAction.enabled = self.nickname != "" && self.nickname != nil
            alert.addAction(chooseAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }

    }
    
    func textChanged(sender:AnyObject) {
        let textField = sender as! UITextField
        var resp : UIResponder = textField
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as! UIAlertController
        
        let chooseAction = alert.actions.first!
        chooseAction.enabled = false
        if let newNickname = textField.text {
            if let match = newNickname.rangeOfString("([a-z|A-Z|0-9])\\w+", options: .RegularExpressionSearch) {
                if match.startIndex == newNickname.startIndex && match.endIndex == newNickname.endIndex {
                    // nickname is valid because the whole string matches
                    chooseAction.enabled = true
                }
            }
        }
        alert.view.tintColor = Constants.Colors.tintColor
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
        let randomUsername = self.randomStringWithLength(20)
        xmppStream.myJID = XMPPJID.jidWithString("\(randomUsername)@\(xmppServer)")
        xmppStream.addDelegate(self, delegateQueue: dispatch_get_main_queue())

        // setting up plugins
        let xmppReconnect = XMPPReconnect()
        xmppReconnect.activate(xmppStream)
        
        // connecting
        do {
            print("connecting")
            statusViewDelegate.updateStatusMessage("connecting")
            try xmppStream.connectWithTimeout(10)
        } catch let error {
            print("Connection error: \(error)")
            showInfoMessage("Connection error", message: "\(error)")
        }
    }
    
    func disconnect() {
        xmppStream.disconnect()
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("authenticated successfully")
        statusViewDelegate.updateStatusMessage("authenticated sucessfully")
        
        xmppRoom = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: XMPPJID.jidWithString("\(mucRoomName)%irc.freenode.net@irc.xmpp.stefantrauth.de"), dispatchQueue: dispatch_get_main_queue())
        xmppRoom.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        xmppRoom.activate(xmppStream)
        
        if nickname == nil {
            if let nickname = userDefaults.objectForKey(userDefaultsNicknameKey) as? String {
                self.nickname = nickname
                print("loaded nickname from user defaults: \(nickname)")
                xmppRoom.joinRoomUsingNickname(nickname, history: nil)
            } else {
                print("could not load nickname from defaults, asking the user now")
                changeNickname("Choose your nickname")
            }
        }
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
        print("did connect")
        if xmppStream.isSecure() {
            do {
                print("authenticating")
                try xmppStream.authenticateAnonymously()
            } catch let error {
                print("error authenticating: \(error)")
                showInfoMessage("Authentication Error", message: "\(error)")
            }
        } else {
            print("securing connection")
            do {
                try xmppStream.secureConnection()
            } catch let error {
                print("failed to secure stream: \(error)")
                showInfoMessage("Failed to secure stream", message: "\(error)")
            }
        }
    }
    
    func xmppStreamDidSecure(sender: XMPPStream!) {
        print("secured stream")
        statusViewDelegate.updateStatusMessage("secured connection")
    }
    
    // MARK: XMPP stream errors
    
    func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        print("error sending message: \(error)")
        showInfoMessage("Could not send message", message: "\(error)")
    }
    
    func xmppStream(sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("could not authenticate \(error)")
        showInfoMessage("Authentication error", message: "\(error)")
    }
    
    func xmppStreamDidDisconnect(sender: XMPPStream!, withError error: NSError!) {
        print("disconnected due to \(error)")
        showInfoMessage("Disonnected", message: "\(error)")
    }
    
    func xmppStream(sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("received error \(error)")
        showInfoMessage("Error Received", message: "\(error)")
    }
    
    func xmppStreamConnectDidTimeout(sender: XMPPStream!) {
        print("timeout")
        showInfoMessage("Timeout", message: "Timeout")
    }
    func xmppStreamWasToldToDisconnect(sender: XMPPStream!) {
        sender.disconnect()
    }
    
    // MARK: - XMPP Room Delegate
    
    func xmppRoom(sender: XMPPRoom!, didReceiveMessage message: XMPPMessage!, fromOccupant occupantJID: XMPPJID!) {
        print("\(message.fromStr()): \(message.body())")
        
        var senderName = message.fromStr().componentsSeparatedByString("/").last
        if senderName == nil {
            senderName = "sender"
        }
        let message = Message(sender: senderName!, text: message.body(), date: NSDate())
        addNewMessage(message)
    }
    
    // TODO this is missing as delegate
    func xmppRoomFailedToJoin() {
        changeNickname("\(nickname) is already taken as a nickname. Choose a different nickname.")
    }
    
    func xmppRoomDidCreate(sender: XMPPRoom!) {
        //xmppRoom.fetchConfigurationForm()
        xmppRoom.configureRoomUsingOptions(nil) // nil to accept default configuration
        print("created room \(sender.roomJID.bare())")
    }
    
//    func xmppRoom(sender: XMPPRoom!, didFetchConfigurationForm configForm: DDXMLElement!) {
//        print("fetched configuration form")
//        print(configForm)
//        let newConfig = configForm.copy() as! DDXMLElement
//        let fields = newConfig.elementsForName("field")
//        for field in fields {
//            let variable = field.attributeStringValueForName("var")
//            if variable == "muc#roomconfig_getmemberlist" {
//                field.removeChildAtIndex(0)
//                field.addChild(DDXMLElement(name: "value", stringValue: "1"))
//            }
//        }
//        
//        xmppRoom.configureRoomUsingOptions(newConfig)
//        print("configured room")
//    }
    
    func xmppRoomDidJoin(sender: XMPPRoom!) {
        print("joined room \(sender.roomJID.bare())")
        statusViewDelegate.updateStatusMessage("")
        self.setTextInputbarHidden(false, animated: true)
        
        print("fetching members")
        xmppRoom.fetchMembersList()
    }
    
    func xmppRoom(sender: XMPPRoom!, didFetchMembersList items: [AnyObject]!) {
        print("members list: \(items)")
    }
    
    func xmppRoom(sender: XMPPRoom!, didNotFetchMembersList iqError: XMPPIQ!) {
        print("could not fetch members list: \(iqError)")
    }
    
    func xmppRoom(sender: XMPPRoom!, occupantDidJoin occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        print("user joined")
    }
    
    func xmppRoom(sender: XMPPRoom!, occupantDidLeave occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        print("user left")
    }
    
    func xmppRoom(sender: XMPPRoom!, occupantDidUpdate occupantJID: XMPPJID!, withPresence presence: XMPPPresence!) {
        print("user updated")
    }
    
    func xmppRoomDidLeave(sender: XMPPRoom!) {
        print("left muc room")
        self.setTextInputbarHidden(true, animated: true)
    }
    
    // MARK: Helper
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRowsInSection(sections - 1)
        self.scrollToRowAtIndexPath(NSIndexPath(forRow: rows - 1, inSection: sections - 1), atScrollPosition: .Bottom, animated: animated)
    }
}