//
//  PlayerViewController.swift
//  Listen
//
//  Created by Stefan Trauth on 23/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    var event: Event? {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        updateUI()
        play(self)
    }
    
    func updateUI() {
        if let event = event {
            coverartImageView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        }
    }
    
    var player: AVPlayer?
    
    @IBOutlet weak var playButton: UIButton!
    @IBAction func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBAction func play(sender: AnyObject) {
        if let event = event {
            
            if player == nil {
                self.player = AVPlayer(URL: event.streamurl)
                //self.player = AVPlayer(URL: NSURL(string: "http://detektor.fm/stream/mp3/musik/")!)
            }
            
            if let player = player {
                player.play()
                //playButton.setTitle("Pause", forState: UIControlState.Normal)
            }

        }
    }
}
