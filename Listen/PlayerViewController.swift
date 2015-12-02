//
//  DemoMusicPlayerController.swift
//  LNPopupControllerExample
//
//  Created by Leo Natan on 8/8/15.
//  Copyright © 2015 Leo Natan. All rights reserved.
//

import UIKit
import MediaPlayer
import Alamofire
import AlamofireImage
import KDEAudioPlayer

class PlayerViewController: UIViewController {
    
    var event: Event! {
        didSet {
            fetchPodcastInfo()
            updateUI()
            togglePlayPause(self)
        }
    }
    var podcast: Podcast?
    var delegate: PlayerDelegator?

	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    let miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var starButtonView: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    
    var statusBarStyle = UIStatusBarStyle.Default
    
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
        // use this to add more controls on ipad interface
		//if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {

        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "brandeis-blue-25-hourglass"), style: .Plain, target: self, action: "togglePlayPause:")]
        
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        miniCoverartImageView.layer.cornerRadius = 5.0
        miniCoverartImageView.layer.masksToBounds = true
        
        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]

	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        updateUI()
	}
    
    func updateUI() {
        podcastNameLabel?.text = event.title
        popupItem.title = event.title
        subtitleLabel?.text = event.podcastDescription
        popupItem.subtitle = event.podcastDescription
        coverartView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        backgroundImageView?.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        miniCoverartImageView.af_setImageWithURL(event.imageurl, placeholderImage: UIImage(named: "event_placeholder"))
        updateProgressBar()
        updateFavoritesButton()
        
        Alamofire.request(.GET, event.imageurl)
            .responseImage { response in
                if let image = response.result.value {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateStatusBarStyle(image)
                    })
                }
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
    
    @IBAction func showEventInfo(sender: AnyObject) {
        delegate?.showEventInfo(event: event)
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
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
                starButtonView?.setImage(UIImage(named: "black-44-star-o"), forState: .Normal)
            } else {
                starButtonView?.setImage(UIImage(named: "black-44-star"), forState: .Normal)
            }
        }
    }
    
    @IBAction func openChat(sender: AnyObject) {
        if let chatUrl = podcast?.chatUrl, let webchatUrl = podcast?.webchatUrl {
            if UIApplication.sharedApplication().canOpenURL(chatUrl) {
                // open associated app
                UIApplication.sharedApplication().openURL(chatUrl)
            } else {
                // open webchat in safari
                UIApplication.sharedApplication().openURL(webchatUrl)
            }
        }
    }
    
    func fetchPodcastInfo() {
        if podcast == nil || podcast!.slug != event.podcastSlug {
            HoersuppeAPI.fetchPodcastDetail(event.podcastSlug, onComplete: { (podcast) -> Void in
                if let podcast = podcast {
                    // check if the request that came back still matches the cell
                    if podcast.slug == self.event.podcastSlug {
                        self.podcast = podcast
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if podcast.webchatUrl != nil {
                                self.chatButton.hidden = false
                            }
                        })
                    }
                }
            })
        }
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("progressUpdate:"), name: "progressUpdate", object: event)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
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
    
    func playerStateChanged(notification: NSNotification) {
        let player = PlayerManager.sharedInstance.player
        
        switch player.state {
        case AudioPlayerState.Buffering:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "brandeis-blue-25-hourglass"), style: .Plain, target: self, action: "togglePlayPause:")]
            playPauseButton?.setImage(UIImage(named: "black-44-hourglass"), forState: UIControlState.Normal)
        case AudioPlayerState.Paused:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "brandeis-blue-25-play"), style: .Plain, target: self, action: "togglePlayPause:")]
            playPauseButton?.setImage(UIImage(named: "black-44-play"), forState: UIControlState.Normal)
        case AudioPlayerState.Playing:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "brandeis-blue-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
            playPauseButton?.setImage(UIImage(named: "black-44-pause"), forState: UIControlState.Normal)
        case AudioPlayerState.Stopped:
            // hide the player
            // TODO
            self.presentingViewController?.dismissPopupBarAnimated(true, completion: nil)
        case AudioPlayerState.WaitingForConnection:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "brandeis-blue-25-hourglass"), style: .Plain, target: self, action: "togglePlayPause:")]
            playPauseButton?.setImage(UIImage(named: "black-44-hourglass"), forState: UIControlState.Normal)
        }
    }
    
}
