//
//  DemoMusicPlayerController.swift
//  LNPopupControllerExample
//
//  Created by Leo Natan on 8/8/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

import UIKit
import Haneke
import MediaPlayer

class PlayerViewController: UIViewController {
    
    var event: Event! {
        didSet {
            updateUI()
            togglePlayPause(self)
        }
    }

	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    let miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
    
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var starButtonView: UIButton!
    
    var statusBarStyle = UIStatusBarStyle.Default
    
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
        // use this to add more controls on ipad interface
		//if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {

        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: self, action: "togglePlayPause")]
        
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]

	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        
        volumeView.showsRouteButton = false // disable airplay icon next to volume slider
        
        visualEffectView.layer.cornerRadius = visualEffectView.frame.size.width/2
        visualEffectView.layer.masksToBounds = true
        
        updateUI()
	}
    
    func updateUI() {
        podcastNameLabel?.text = event.title
        popupItem.title = event.title
        subtitleLabel?.text = event.podcastDescription
        popupItem.subtitle = event.podcastDescription
        coverartView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        backgroundImageView?.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        miniCoverartImageView.hnk_setImageFromURL(event.imageurl, placeholder: UIImage(named: "event_placeholder"), format: nil, failure: nil, success: nil)
        updateProgressBar()
        updateFavoritesButton()
        
        // fetch coverart from image cache and set it as lockscreen artwork
        let imageCache = Shared.imageCache
        imageCache.fetch(URL: event.imageurl).onSuccess { (image) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateStatusBarStyle(image)
            })
        }
    }
    
    func updateStatusBarStyle(image: UIImage) {
        if image.averageColor().isDarkColor() {
            statusBarStyle = UIStatusBarStyle.LightContent
        } else {
            statusBarStyle = UIStatusBarStyle.Default
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func favorite(sender: AnyObject) {
        if let event = event {
            Favorites.toggle(slug: event.podcastSlug)
        }
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        Player.sharedInstance.togglePlayPause(event)
    }

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
	}
	
    func updateProgressBar() {
        let progress = event.progress
        popupItem.progress = progress
        progressView?.progress = progress
    }
    
    func updateFavoritesButton() {
        if let event = event {
            if !Favorites.fetch().contains(event.podcastSlug) {
                starButtonView?.setTitle("☆", forState: .Normal)
            } else {
                starButtonView?.setTitle("★", forState: .Normal)
            }
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("progressUpdate:"), name: "progressUpdate", object: event)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerRateChanged:"), name: "playerRateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func progressUpdate(notification: NSNotification) {
        updateProgressBar()
	}

    func favoritesChanged(notification: NSNotification) {
        updateFavoritesButton()
    }
    
    func playerRateChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let player = userInfo["player"] as! Player
        if player.isPlaying {
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: self, action: "togglePlayPause")]
            playPauseButton?.setImage(UIImage(named: "nowPlaying_pause"), forState: UIControlState.Normal)
        } else {
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "play"), style: .Plain, target: self, action: "togglePlayPause")]
            playPauseButton?.setImage(UIImage(named: "nowPlaying_play"), forState: UIControlState.Normal)
        }
    }
    
}
