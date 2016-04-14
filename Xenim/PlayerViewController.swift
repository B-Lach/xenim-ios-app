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

class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var backgroundCoverartImageView: UIImageView!
    
    weak var presenter: UITabBarController!
    var event: Event! {
        didSet {
            updateUI()
        }
    }
    
    var miniCoverartImageView: UIImageView!

    @IBOutlet weak var timeLeftLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
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
    
    @IBOutlet weak var sleepTimerButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var airplayView: MPVolumeView! {
        didSet {
            airplayView.showsVolumeSlider = false
        }
    }
    
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
        timer = NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: #selector(timerTicked), userInfo: nil, repeats: true)
        timerTicked()
        
        self.listenersCountLabel.text = "\(event.listeners!)"
        
        popupItem.title = event.podcast.name
        popupItem.subtitle = event.title
        if let imageurl = event.podcast.artwork.thumb150Url {
            miniCoverartImageView.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"), imageTransition: .CrossDissolve(0.2))
        }
        
        setupNotifications()
        updateUI()
        
        currentTimeLabel.hidden = true
        timeLeftLabel.hidden = true
	}
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // use this to add more controls on ipad interface
        //if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {
        
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: #selector(PlayerViewController.togglePlayPause(_:)))]
        
        miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        miniCoverartImageView.layer.cornerRadius = 5.0
        miniCoverartImageView.layer.masksToBounds = true
        
        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
        updateFavoritesButton()
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
                favoriteButton?.setImage(UIImage(named: "star-outline"), forState: .Normal)
            } else {
                favoriteButton?.setImage(UIImage(named: "star"), forState: .Normal)
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
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        if let event = event {
            Favorites.toggle(podcastId: event.podcast.id)
        }
    }
    
    @IBAction func share(sender: AnyObject) {
        if let url = event?.eventXenimWebUrl {
            let objectsToShare = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
            // Excluded Activities
            //      activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
    }
    
    @IBAction func backwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.backwardPressed()
    }
    
    @IBAction func forwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.forwardPressed()
    }
    
    @IBAction func dismissPopup(sender: AnyObject) {
        presenter.closePopupAnimated(true, completion: nil)
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
        sleepTimer?.invalidate()
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "star"), forState: .Normal)
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "star-outline"), forState: .Normal)
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
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        case .Paused:
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        case .Playing:
            playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        case .Stopped:
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        case .WaitingForConnection:
            playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = false
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        case .Failed(_):
            playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
            loadingSpinnerView.hidden = true
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: #selector(PlayerManager.togglePlayPause(_:)))]
        }
    }

    // MARK: - delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let baseViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.view.tintColor = Constants.Colors.tintColor
        let endPlayback = NSLocalizedString("player_manager_actionsheet_end_playback", value: "End Playback", comment: "long pressing in the player view shows an action sheet to end playback. this is the action message to end playback.")
        alert.addAction(UIAlertAction(title: endPlayback, style: UIAlertActionStyle.Destructive, handler: { (_) -> Void in
            // dissmiss the action sheet
            baseViewController!.dismissViewControllerAnimated(true, completion: nil)
            PlayerManager.sharedInstance.stop()
        }))
        let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel")
        alert.addAction(UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel, handler: nil))
        baseViewController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - sleeptimer
    
    var sleepTimerTicksLeft: Int?
    var sleepTimer: NSTimer?
    
    @IBAction func sleepTimerPressed(sender: AnyObject) {
        if sleepTimer != nil {
            disableSleepTimer()
        } else {
            // show action sheet to select time
            // 10, 20, 30, 60 minutes
            
            let optionMenu = UIAlertController(title: "Sleep Timer", message: "When do you want the player to stop playing?", preferredStyle: .ActionSheet)
            optionMenu.view.tintColor = Constants.Colors.tintColor
            
            for minutes in [1, 10, 20, 30, 60] {
                let action = UIAlertAction(title: "\(minutes)min", style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                    self.enableSleepTimer(minutes: minutes)
                })
                optionMenu.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "cancel string"), style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    private func enableSleepTimer(minutes minutes: Int) {
        let oneMinute: NSTimeInterval = 60
        sleepTimer = NSTimer.scheduledTimerWithTimeInterval(oneMinute, target: self, selector: #selector(sleepTimerTriggered), userInfo: nil, repeats: true)
        sleepTimerTicksLeft = minutes
        updateSleepTimerDisplay()
    }
    
    private func disableSleepTimer() {
        sleepTimerTicksLeft = nil
        sleepTimer?.invalidate()
        sleepTimer = nil
        updateSleepTimerDisplay()
    }

    @objc func sleepTimerTriggered() {
        sleepTimerTicksLeft = sleepTimerTicksLeft! - 1
        if sleepTimerTicksLeft == 0 {
            disableSleepTimer()
            PlayerManager.sharedInstance.stop()
        }
        updateSleepTimerDisplay()
    }
    
    private func updateSleepTimerDisplay() {
        if let minutesLeft = sleepTimerTicksLeft {
            sleepTimerButton.setTitle("\(minutesLeft)min", forState: .Normal)
        } else {
            sleepTimerButton.setTitle("", forState: .Normal)
        }
        
    }
    
}
