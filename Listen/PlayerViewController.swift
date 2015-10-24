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
    let miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
    
    var player: AVPlayer?
    var timer : NSTimer?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
//		if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {

        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: nil, action: nil)]
        
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]
        
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "_timerTicked:", userInfo: nil, repeats: true)

	}
    
    var event: Event! {
        didSet {
            updateUI()
            play()
        }
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            
        }
        updateUI()
        play()
	}
    
    func play(){
        player = AVPlayer(URL: event.streamurl)
        //self.player = AVPlayer(URL: NSURL(string: "http://detektor.fm/stream/mp3/musik/")!)
        
        if let player = player {
            player.play()
            //playButton.setTitle("Pause", forState: UIControlState.Normal)
        }
    }
    
    func updateUI() {
        if let event = event {
            podcastNameLabel?.text = event.title
            popupItem.title = event.title
            subtitleLabel?.text = event.description
            popupItem.subtitle = event.description
            coverartView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
            backgroundImageView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
            miniCoverartImageView.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
            _timerTicked(timer!)
        }
    }

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}
	
    // update progress every minute
	func _timerTicked(timer: NSTimer) {
        //print("tick \(event.title)")
        // progress is a value between 0 and 1
        let progress = (Float)(event.progress())
		popupItem.progress = progress
		progressView?.progress = progress
		
//		if popupItem.progress == 1.0 {
//			timer.invalidate()
//			popupPresentationContainerViewController?.dismissPopupBarAnimated(true, completion: nil)
//		}
	}
}
