//
//  DemoMusicPlayerController.swift
//  LNPopupControllerExample
//
//  Created by Leo Natan on 8/8/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

import UIKit
//import AlamofireImage
import AVFoundation

class PlayerViewController: UIViewController {

	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
//    let imageCache = AutoPurgingImageCache()
    
    var player: AVPlayer?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {
			self.popupItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "prev"), style: .Plain, target: nil, action: nil),
												UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: nil, action: nil),
												UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .Plain, target: nil, action: nil)]
			self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "next"), style: .Plain, target: nil, action: nil),
												UIBarButtonItem(image: UIImage(named: "action"), style: .Plain, target: nil, action: nil)]
		}
		else {
			self.popupItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: nil, action: nil)]
			self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "action"), style: .Plain, target: nil, action: nil)]
		}

	}
    
    var event: Event! {
        didSet {
            updateUI()
        }
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        play()
	}
    
    func play(){
        if player == nil {
            self.player = AVPlayer(URL: event.streamurl)
            //self.player = AVPlayer(URL: NSURL(string: "http://detektor.fm/stream/mp3/musik/")!)
        }
        
        if let player = player {
            player.play()
            //playButton.setTitle("Pause", forState: UIControlState.Normal)
        }

    }
    
    func updateUI() {
        if let event = event {
            podcastNameLabel?.text = event.title
            popupItem.title = event.title
            subtitleLabel?.text = event.url
            popupItem.subtitle = event.url
            coverartView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
            backgroundImageView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        }
    }

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}
	
//	func _timerTicked(timer: NSTimer) {
//		popupItem.progress += 0.007;
//		progressView.progress = popupItem.progress
//		
//		if popupItem.progress == 1.0 {
//			timer.invalidate()
//			popupPresentationContainerViewController?.dismissPopupBarAnimated(true, completion: nil)
//		}
//	}
}
