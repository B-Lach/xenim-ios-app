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

class PlayerViewController: UIViewController {
    
    var event: Event!
    
    @IBOutlet weak var loadingSpinnerView: SpinnerView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var sleepTimerButton: UIButton!
    @IBOutlet weak var airplayView: MPVolumeView! {
        didSet {
            airplayView.showsVolumeSlider = false
            for view in airplayView.subviews {
                if view.isKindOfClass(UIButton) {
                    let buttonOnVolumeView : UIButton = view as! UIButton
                    airplayView.setRouteButtonImage(buttonOnVolumeView.currentImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerManager.sharedInstance.play(event)
        
        title = event.podcast.name
        
        setupNotifications()
        
        setupVoiceOver()
        
        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Phone:
            if let imageurl = event.podcast.artwork.thumb800Url {
                coverartView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .CrossDissolve(0.2))
            }
        case .Pad:
            if let imageurl = event.podcast.artwork.thumb3000Url {
                coverartView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .CrossDissolve(0.2))
            }
        default: break
        }
        
        updateFavoritesButton()
	}
    
    override func viewWillDisappear(animated: Bool) {
        PlayerManager.sharedInstance.stop()
    }
    
    private func setupVoiceOver() {
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
    }
    
    // MARK: - Update UI
    
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
            activityVC.popoverPresentationController?.sourceView = shareButton
                
            // Excluded Activities
            //      activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause()
    }
    
    @IBAction func backwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.minus30seconds()
    }
    
    @IBAction func forwardPressed(sender: AnyObject) {
        PlayerManager.sharedInstance.plus30seconds()
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.playerStateChanged(_:)), name: "playerStateChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        sleepTimer?.invalidate()
    }
    
    func updateFavoritesButton() {
        if let event = event {
            updateFavoritesButton(Favorites.isFavorite(event.podcast.id))
        }
    }
    
    private func updateFavoritesButton(isFavorite: Bool) {
        if isFavorite {
            favoriteButton.image = UIImage(named: "star_25")
            favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
        } else {
            favoriteButton.image = UIImage(named: "star_o_25")
            favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
        }
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            if podcastId == event.podcast.id {
                updateFavoritesButton(true)
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            if podcastId == event.podcast.id {
                updateFavoritesButton(false)
            }
        }
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
        case .Failed:
            showPlaybuttonPaused()
            showStreamErrorMessage()
        }
    }
    
    private func showStreamErrorMessage() {
        let errorTitle = NSLocalizedString("player_failed_state_alertview_title", value: "Playback Error", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the title.")
        let errorMessage = NSLocalizedString("player_failed_state_alertview_message", value: "The selected stream can not be played.", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the message.")
        showInfoMessage(errorTitle, message: errorMessage)
    }
    
    private func showPlaybuttonPlaying() {
        loadingSpinnerView.hidden = true
        playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_playing", value: "playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_playing", value: "double tap to pause", comment: "")
    }
    
    private func showPlaybuttonPaused() {
        loadingSpinnerView.hidden = true
        playPauseButton?.setImage(UIImage(named: "large-play"), forState: UIControlState.Normal)
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_not_playing", value: "not playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_not_playing", value: "double tap to play", comment: "")
    }
    
    private func showPlaybuttonBuffering() {
        loadingSpinnerView.hidden = false
        playPauseButton?.setImage(UIImage(named: "large-pause"), forState: UIControlState.Normal)
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_buffering", value: "buffering", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_buffering", value: "double tap to pause", comment: "")
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
            optionMenu.popoverPresentationController?.sourceView = sleepTimerButton
            
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
