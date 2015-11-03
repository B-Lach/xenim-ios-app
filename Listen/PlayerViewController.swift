//
//  DemoMusicPlayerController.swift
//  LNPopupControllerExample
//
//  Created by Leo Natan on 8/8/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Haneke

class PlayerViewController: UIViewController {

	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    let miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
    
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var playPauseButton: UIButton!
    
    var isPlaying:Bool {
        get {
                // rate is always between 0 and 1
                // a rate greater than 0 means its playing
                return player.rate > 0
        }
    }
    var player = AVPlayer()
    var timer : NSTimer?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
        // use this to add more controls on ipad interface
		//if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {

        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: self, action: "pause")]
        
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]

	}
    
    var event: Event! {
        didSet {
            updateUI()
            player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: event.streamurl))
            play()
        }
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // required to play audio in background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {}
        setupRemoteCommands()
        
        // setup timer to update progressbar every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "timerTicked", userInfo: nil, repeats: true)
        player = AVPlayer(URL: event.streamurl)
        volumeView.showsRouteButton = false // disable airplay icon next to volume slider
        
        updateUI()
        play()
	}
    
    func updateUI() {
        podcastNameLabel?.text = event.title
        popupItem.title = event.title
        subtitleLabel?.text = event.description
        popupItem.subtitle = event.description
        coverartView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        backgroundImageView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        miniCoverartImageView.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        timerTicked()
        
        // fetch coverart from image cache and set it as lockscreen artwork
        let imageCache = Shared.imageCache
        imageCache.fetch(URL: event.imageurl).onSuccess { (image) -> () in
            let songInfo: Dictionary = [
                MPMediaItemPropertyTitle: self.event.title,
                MPMediaItemPropertyArtist: self.event.description,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
    }
    
    func setupRemoteCommands() {
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.togglePlayPauseCommand.addTarget(self, action: "togglePlayPause")
        commandCenter.togglePlayPauseCommand.enabled = true
    }
    
    func togglePlayPause() {
        print("Toggled")
    }
    
    func pause() {
        player.pause()
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "play"), style: .Plain, target: self, action: "play")]
        playPauseButton?.setImage(UIImage(named: "nowPlaying_play"), forState: UIControlState.Normal)
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play(){
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        player.play()
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: self, action: "pause")]
        playPauseButton?.setImage(UIImage(named: "nowPlaying_pause"), forState: UIControlState.Normal)
    }

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}
	
    // update progress every minute
	func timerTicked() {
        // progress is a value between 0 and 1
        let progress = (Float)(event.progress())
		popupItem.progress = progress
		progressView?.progress = progress
	}
}
