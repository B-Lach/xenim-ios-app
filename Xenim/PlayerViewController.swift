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

    @IBOutlet weak var listenersCountLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var loadingSpinnerView: SpinnerView!
    @IBOutlet weak var blurView: UIVisualEffectView!
	@IBOutlet weak var podcastNameLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var coverartView: UIImageView! {
        didSet {
            if let image = coverartView.image {
                image.getColors({ (colors) in
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.progressView.progressTintColor = colors.backgroundColor
                    })
                })
            }
        }
    }
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var sleepTimerButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    weak var miniplayerPlayPauseBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var airplayView: MPVolumeView! {
        didSet {
            airplayView.showsVolumeSlider = false
        }
    }
    
    var timer : NSTimer? // timer to update view periodically

    let updateInterval: NSTimeInterval = 60 // seconds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // use this to add more controls on ipad interface
        //if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {
        
        let playPauseItem = UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: #selector(togglePlayPause(_:)))
        miniplayerPlayPauseBarButtonItem = playPauseItem
        self.popupItem.rightBarButtonItems = [miniplayerPlayPauseBarButtonItem]
        
        miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        miniCoverartImageView.layer.cornerRadius = 5.0
        miniCoverartImageView.layer.masksToBounds = true
        
        let coverartBarButtonItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [coverartBarButtonItem]
        
        
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
        
        setupVoiceOver()
	}
    
    private func setupVoiceOver() {
        popupItem.accessibilityHint = NSLocalizedString("voiceover_playerbar_hint", value: "double tap to max the player", comment: "")
        
        listenersCountLabel.accessibilityLabel = NSLocalizedString("voiceover_listeners_count_label", value: "listeners", comment: "")
        dismissButton.accessibilityLabel = NSLocalizedString("voiceover_dismiss_button_label", value: "minify", comment: "")
        dismissButton.accessibilityHint = NSLocalizedString("voiceover_dismiss_button_hint", value: "double tap minify the player", comment: "")
        
        favoriteButton.accessibilityLabel = " "
        favoriteButton.accessibilityHint = NSLocalizedString("voiceover_favorite_button_hint", value: "double tap to toggle favorite", comment: "")
        shareButton.accessibilityLabel = NSLocalizedString("voiceover_share_button_label", value: "share", comment: "")
        
        playPauseButton.accessibilityLabel = NSLocalizedString("voiceover_play_button_label", value: "play button", comment: "")
        
        skipForwardButton.accessibilityLabel = NSLocalizedString("voiceover_forward_button_label", value: "forward", comment: "")
        skipForwardButton.accessibilityHint = NSLocalizedString("voiceover_forward_button_hint", value: "double tap to skip 30 seconds forward", comment: "")
        skipBackwardButton.accessibilityLabel = NSLocalizedString("voiceover_backward_button_label", value: "backward", comment: "")
        skipBackwardButton.accessibilityHint = NSLocalizedString("voiceover_backward_button_hint", value: "double tap to skip 30 seconds backward", comment: "")
        
        sleepTimerButton.accessibilityLabel = NSLocalizedString("voiceover_sleep_button_label", value: "sleep timer", comment: "")
        sleepTimerButton.accessibilityValue = NSLocalizedString("voiceover_sleep_button_value_disabled", value: "disabled", comment: "")
        sleepTimerButton.accessibilityHint = NSLocalizedString("voiceover_sleep_button_hint_configure", value: "double tap to configure a sleep timer", comment: "")
        
        // disable these labels from accessibility as they do not have any function yet
        progressView.isAccessibilityElement = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
                    self.listenersCountLabel.accessibilityValue = "\(listeners)"
                })
            }
        }
    }
    
    func updateFavoritesButton() {
        if let event = event {
            if !Favorites.isFavorite(event.podcast.id) {
                favoriteButton?.setImage(UIImage(named: "star_o_25"), forState: .Normal)
                favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
            } else {
                favoriteButton?.setImage(UIImage(named: "star_25"), forState: .Normal)
                favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
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
                favoriteButton?.setImage(UIImage(named: "star_25"), forState: .Normal)
                favoriteButton?.tintColor = UIColor.whiteColor().colorWithAlphaComponent(1)
                favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "star_o_25"), forState: .Normal)
                favoriteButton?.tintColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
                favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
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
            showPlaybuttonBuffering()
        case .Paused:
            showPlaybuttonPaused()
        case .Playing:
            showPlaybuttonPlaying()
        case .Stopped:
            showPlaybuttonPaused()
        case .WaitingForConnection:
            showPlaybuttonBuffering()
        case .Failed(_):
            showPlaybuttonPaused()
        }
    }
    
    private func showPlaybuttonPlaying() {
        loadingSpinnerView.hidden = true
        playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
        miniplayerPlayPauseBarButtonItem.image = UIImage(named: "scarlet-25-pause")
        miniplayerPlayPauseBarButtonItem.accessibilityLabel = NSLocalizedString("voiceover_play_button_label", value: "play button", comment: "")
        miniplayerPlayPauseBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_playing", value: "playing", comment: "")
        miniplayerPlayPauseBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_playing", value: "double tap to pause", comment: "")
        
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_playing", value: "playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_playing", value: "double tap to pause", comment: "")
    }
    
    private func showPlaybuttonPaused() {
        loadingSpinnerView.hidden = true
        playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
        miniplayerPlayPauseBarButtonItem.image = UIImage(named: "scarlet-25-play")
        miniplayerPlayPauseBarButtonItem.accessibilityLabel = "Play Button"
        miniplayerPlayPauseBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_not_playing", value: "not playing", comment: "")
        miniplayerPlayPauseBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_not_playing", value: "double tap to play", comment: "")
        
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_not_playing", value: "not playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_not_playing", value: "double tap to play", comment: "")
    }
    
    private func showPlaybuttonBuffering() {
        loadingSpinnerView.hidden = false
        playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
        miniplayerPlayPauseBarButtonItem.image = UIImage(named: "scarlet-25-pause")
        miniplayerPlayPauseBarButtonItem.accessibilityLabel = NSLocalizedString("voiceover_play_button_label", value: "play button", comment: "")
        miniplayerPlayPauseBarButtonItem.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_buffering", value: "buffering", comment: "")
        miniplayerPlayPauseBarButtonItem.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_buffering", value: "double tap to pause", comment: "")
        
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_buffering", value: "buffering", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_buffering", value: "double tap to pause", comment: "")
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
    
    private var sleepTimerTicksLeft: Int?
    private weak var sleepTimer: NSTimer?
    
    @IBAction func sleepTimerPressed(sender: AnyObject) {
        if sleepTimer != nil {
            disableSleepTimer()
        } else {
            // show action sheet to select time
            // 10, 20, 30, 60 minutes
            
            let optionMenu = UIAlertController(title: "", message: "", preferredStyle: .ActionSheet)
            optionMenu.view.tintColor = Constants.Colors.tintColor
            
            for minutes in [10, 20, 30, 60] {
                let action = UIAlertAction(title: "\(minutes)min", style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                    self.enableSleepTimer(minutes: minutes)
                })
                optionMenu.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "Cancel"), style: .Cancel, handler: {
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
            
            sleepTimerButton.accessibilityValue = String.localizedStringWithFormat(NSLocalizedString("voiceover_sleep_button_value", value: "%@ minutes left", comment: ""), "\(minutesLeft)")
            sleepTimerButton.accessibilityHint = NSLocalizedString("voiceover_sleep_button_hint_disable", value: "Double Tap to disable the sleep timer", comment: "")
        } else {
            sleepTimerButton.setTitle("", forState: .Normal)
            sleepTimerButton.accessibilityValue = NSLocalizedString("voiceover_sleep_button_value_disabled", value: "disabled", comment: "")
            sleepTimerButton.accessibilityHint = NSLocalizedString("voiceover_sleep_button_hint_configure", value: "double tap to configure a sleep timer", comment: "")
        }
        
    }
    
}
