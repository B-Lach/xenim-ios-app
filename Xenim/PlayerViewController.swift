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
    
    weak var statusBarStyleDelegate: StatusBarDelegate!
    weak var pageViewDelegate: PageViewDelegate!
    weak var popupDelegate: PopupDelegate!
        
    var event: Event! {
        didSet {
            updateUI()
        }
    }

    @IBOutlet weak var listenersCountLabel: UILabel!
    @IBOutlet weak var listenersIconImageView: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        let effect = UIBlurEffect(style: .Dark)
//        let vibrancy = UIVibrancyEffect(forBlurEffect: effect)
//        blurView.effect = vibrancy
        
        // setup timer to update every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: #selector(PlayerViewController.timerTicked), userInfo: nil, repeats: true)
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
    
    override func viewDidAppear(animated: Bool) {
        updateStatusBarColor()
    }
    
    // MARK: - Update UI
    
    func updateUI() {        
        podcastNameLabel?.text = event.podcast.name
        subtitleLabel?.text = event.title

        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.originalUrl {
            coverartView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
            backgroundCoverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartView?.image = placeholderImage
        }
        
        updateProgressBar()
        updateToolbar()
        updateFavoritesButton()
    }
    
    func updateStatusBarColor() {
        statusBarStyleDelegate.updateStatusBarStyle(.LightContent)
    }
    
    func updateToolbar() {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        var items = [UIBarButtonItem]()
        
        if event.podcast.webchatUrl != nil {
            let chatItem = UIBarButtonItem(image: UIImage(named: "chat"), style: .Plain, target: self, action: #selector(PlayerViewController.openChat(_:)))
            items.append(spaceItem)
            items.append(chatItem)
        }
        
        favoriteItem = UIBarButtonItem(image: UIImage(named: "star-outline"), style: .Plain, target: self, action: #selector(PlayerViewController.favorite(_:)))
        items.append(spaceItem)
        items.append(favoriteItem!)
        
        let shareItem = UIBarButtonItem(image: UIImage(named: "share"), style: .Plain, target: self, action: #selector(PlayerViewController.share(_:)))
        items.append(spaceItem)
        items.append(shareItem)
        
        let infoItem = UIBarButtonItem(image: UIImage(named: "info-outline"), style: .Plain, target: self, action: #selector(PlayerViewController.showEventInfo(_:)))
        items.append(spaceItem)
        items.append(infoItem)
        
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
            if !Favorites.isFavorite(event.podcast.id) {
                favoriteItem?.image = UIImage(named: "star-outline")
            } else {
                favoriteItem?.image = UIImage(named: "star")
            }
        }
    }
    
    func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
        pageViewDelegate.showPage(1)
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
    }
    
    func openChat(sender: AnyObject) {
        if let webchatUrl = event.podcast.webchatUrl {
            UIApplication.sharedApplication().openURL(webchatUrl)
        } else {
            let message = NSLocalizedString("player_view_no_chat_url", value: "There is no chat for this podcast", comment: "alert message presented to the user if chat button is pressed but there is no chat url for this podcast.")
            showInfoMessage("Info", message: message)
        }
    }
    
    @IBAction func backwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.backwardPressed()
    }
    
    @IBAction func forwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.forwardPressed()
    }
    
    @IBAction func dismissPopup(sender: AnyObject) {
        popupDelegate.minify()
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.playerStateChanged(_:)), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer?.invalidate()
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteItem?.image = UIImage(named: "star")
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteItem?.image = UIImage(named: "star-outline")
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
            playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = false
        case .Paused:
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .Playing:
            playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .Stopped:
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        case .WaitingForConnection:
            playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = false
        case .Failed(_):
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
        }
    }
    
}
