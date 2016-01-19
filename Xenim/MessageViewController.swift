//
//  MessageViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel! {
        didSet {
            messageLabel?.text = message
        }
    }
    var message: String! {
        didSet {
            messageLabel?.text = message
        }
    }
}
