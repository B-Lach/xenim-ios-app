//
//  PlayerViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 09/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import MediaPlayer
import Alamofire
import AlamofireImage
import KDEAudioPlayer
import UIImageColors

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var backgroundCoverartImageView: UIImageView!
        
    var event: Event! {
        didSet {
            updateUI()
        }
    }

    @IBOutlet weak var listenersCountLabel: UILabel!
    @IBOutlet weak var listenersIconImageView: UIImageView! {
        didSet {
            // set rendering mode to template to set tint color
            listenersIconImageView.image = listenersIconImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    var coverartColors: UIImageColors? {
        didSet {
            if let colors = coverartColors {
                if colors.backgroundColor.isDarkColor {
                    statusBarStyle = .LightContent
                } else {
                    statusBarStyle = .Default
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                    self.listenersCountLabel.textColor = colors.primaryColor
                    self.listenersIconImageView.tintColor = colors.primaryColor
                })
            }

        }
    }

    @IBOutlet weak var loadingSpinnerView: SpinnerView!
    @IBOutlet weak var blurView: UIVisualEffectView!
	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    var favoriteItem: UIBarButtonItem?
    
    var timer : NSTimer? // timer to update view periodically
    let updateInterval: NSTimeInterval = 60 // seconds
    
    var statusBarStyle = UIStatusBarStyle.Default
	
    override func viewDidLoad() {
        super.viewDidLoad()

//        let effect = UIBlurEffect(style: .Dark)
//        let vibrancy = UIVibrancyEffect(forBlurEffect: effect)
//        blurView.effect = vibrancy
        
        // setup timer to update every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("timerTicked"), userInfo: nil, repeats: true)
        timerTicked()
        
        toolbar.setBackgroundImage(UIImage(),
            forToolbarPosition: UIBarPosition.Any,
            barMetrics: UIBarMetrics.Default)
        toolbar.setShadowImage(UIImage(),
            forToolbarPosition: UIBarPosition.Any)
        
        self.listenersCountLabel.text = "\(event.listeners!)"
        
        setupNotifications()
        updateUI()
	}
    
    // MARK: - Update UI
    
    func updateUI() {
        let title = event.title != nil ? event.title : event.podcast.name
        let description = event.eventDescription != nil ? event.eventDescription : event.podcast.podcastDescription
        
        podcastNameLabel?.text = title
        popupItem.title = title
        subtitleLabel?.text = description
        popupItem.subtitle = description

        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.originalUrl {
            coverartView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            backgroundCoverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))

            Alamofire.request(.GET, imageurl)
                .responseImage { response in
                    if let image = response.result.value {
                        self.coverartColors = image.getColors()
                    }
            }
        } else {
            coverartView?.image = placeholderImage
        }
        
        updateProgressBar()
        updateToolbar()
        updateFavoritesButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
    
    func updateToolbar() {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        var items = [UIBarButtonItem]()
        
        favoriteItem = UIBarButtonItem(image: UIImage(named: "scarlet-25-star-o"), style: .Plain, target: self, action: "favorite:")
        items.append(spaceItem)
        items.append(favoriteItem!)
        
        let infoItem = UIBarButtonItem(image: UIImage(named: "scarlet-25-info"), style: .Plain, target: self, action: "showEventInfo:")
        items.append(spaceItem)
        items.append(infoItem)
        
        if event.podcast.webchatUrl != nil {
            let chatItem = UIBarButtonItem(image: UIImage(named: "scarlet-25-comments"), style: .Plain, target: self, action: "openChat:")
            items.append(spaceItem)
            items.append(chatItem)
        }
        
        let shareItem = UIBarButtonItem(image: UIImage(named: "scarlet-25-share"), style: .Plain, target: self, action: "share:")
        items.append(spaceItem)
        items.append(shareItem)
        
        items.append(spaceItem)
        toolbar?.setItems(items, animated: true)
    }
    
    func updateProgressBar() {
        let progress = event.progress
        popupItem.progress = progress
        progressView?.progress = progress
    }
    
    func updateListeners() {
        event.fetchCurrentListeners { (listeners) -> Void in
            if let listeners = listeners {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.listenersCountLabel.text = "\(listeners)"
                })
            }
        }
    }
    
    func updateFavoritesButton() {
        if let event = event {
            if !Favorites.fetch().contains(event.podcast.id) {
                favoriteItem?.image = UIImage(named: "scarlet-25-star-o")
            } else {
                favoriteItem?.image = UIImage(named: "scarlet-25-star")
            }
        }
    }
    
    // MARK: - Actions
    
    func favorite(sender: AnyObject) {
        if let event = event {
            Favorites.toggle(podcastId: event.podcast.id)
        }
    }
    
    func share(sender: AnyObject) {
        if let url = event?.eventXenimWebUrl {
            let objectsToShare = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
            // Excluded Activities
            //      activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    func showEventInfo(sender: AnyObject) {
        PodcastDetailViewController.showPodcastInfo(podcast: event.podcast)
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
    }
    
    func openChat(sender: AnyObject) {
        if let ircUrl = event.podcast.ircUrl, let webchatUrl = event.podcast.webchatUrl {
            if UIApplication.sharedApplication().canOpenURL(ircUrl) {
                // open associated app
                UIApplication.sharedApplication().openURL(ircUrl)
            } else {
                // open webchat in safari
                UIApplication.sharedApplication().openURL(webchatUrl)
            }
        }
    }
    
    @IBAction func backwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.backwardPressed()
    }
    
    @IBAction func forwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.forwardPressed()
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteAdded:"), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteRemoved:"), name: "favoriteRemoved", object: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteItem?.image = UIImage(named: "scarlet-25-star")
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteItem?.image = UIImage(named: "scarlet-25-star-o")
            }
        }
    }
    
    @objc func timerTicked() {
        updateProgressBar()
        updateListeners()
	}
    
    func playerStateChanged(notification: NSNotification) {
        let player = PlayerManager.sharedInstance.player
        
        switch player.state {
        case .Buffering:
            playPauseButton?.setImage(UIImage(named: "Pause-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = false
        case .Paused:
            playPauseButton?.setImage(UIImage(named: "Play-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .Playing:
            playPauseButton?.setImage(UIImage(named: "Pause-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .Stopped:
            playPauseButton?.setImage(UIImage(named: "Play-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .WaitingForConnection:
            playPauseButton?.setImage(UIImage(named: "Pause-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = false
        case .Failed(_):
            playPauseButton?.setImage(UIImage(named: "Play-white"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        }
    }
    
}
