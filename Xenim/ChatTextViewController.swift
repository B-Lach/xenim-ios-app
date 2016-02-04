//
//  ChatTextViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import SlackTextViewController

struct Message {
    var sender: String
    var text: String
    var date: NSDate
}

class ChatTextViewController: SLKTextViewController {
    
    var messages = [Message]()
    
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
        // send message
        self.textView.refreshFirstResponder()
        let testMessage = Message(sender: "funkenstrahlen", text: textView.text, date: NSDate())
        textView.text = ""
        addNewMessage(testMessage)
    }
    
    private func addNewMessage(message: Message) {
        tableView.beginUpdates()
        messages.append(message)
        let indexPath = NSIndexPath(forRow: messages.count - 1, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        tableView.endUpdates()
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
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