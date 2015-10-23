//
//  PlayerViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 23/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    
    var event: Event? {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        updateUI()
    }
    
    func updateUI() {
        if let event = event {
            coverartImageView?.af_setImageWithURL(NSURL(string: event.imageurl)!, placeholderImage: UIImage(named: "event_placeholder"))
        }
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBAction func play(sender: AnyObject) {
    }
}
