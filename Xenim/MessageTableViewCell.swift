//
//  MessageTableViewCell.swift
//  Xenim
//
//  Created by Stefan Trauth on 04/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var messageContentLabel: UILabel!
    
    var message: Message! {
        didSet {
            senderLabel.text = message.sender
            messageContentLabel.text = message.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
