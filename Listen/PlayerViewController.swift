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
    }
    
    func updateUI() {
        if let event = event {
            coverartImageView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        }
    }
    
    var player: AVAudioPlayer?
    
    @IBOutlet weak var playButton: UIButton!
    @IBAction func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBAction func play(sender: AnyObject) {
        if let event = event {
            
            if player == nil {
                do {
                    try self.player = AVAudioPlayer(contentsOfURL: event.streamurl)
                    
                } catch {
                    // can't initialize player
                }
            }
            
            if let player = player {
                if player.playing {
                    player.pause()
                    if !player.playing {
                        playButton.setTitle("Play", forState: UIControlState.Normal)
                    }
                } else {
                    player.play()
                    if player.playing {
                        playButton.setTitle("Pause", forState: UIControlState.Normal)
                    }
                }
            }

        }
    }
}
