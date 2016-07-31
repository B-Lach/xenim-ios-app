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

class PlayerViewController: UIViewController {
    
    var event: Event! {
        didSet {
            if event.title == nil {
                event.title = "Livestream"
            }
        }
    }
    private var player: AVPlayer!
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var timeLeftLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var loadingSpinnerView: SpinnerView!
    @IBOutlet weak var coverartView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var listenersCountButton: UIButton!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var sleepTimerButton: UIButton!
    @IBOutlet weak var airplayView: MPVolumeView! {
        didSet {
            // TODO
//            airplayView.showsVolumeSlider = false
//            for view in airplayView.subviews {
//                if view.isKind(of: UIButton) {
//                    let buttonOnVolumeView : UIButton = view as! UIButton
//                    self.airplayView.setRouteButtonImage(buttonOnVolumeView.currentImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
//                }
//            }
        }
    }
    
    var updateListenersTimer: Timer?
    private var observerContext = 0
    private var timeObserver: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = event.podcast.name
        
        setupPlayerAndPlay()
        setupVoiceOver()
        
        listenersCountButton.isUserInteractionEnabled = false
        
        switch UIDevice.current().userInterfaceIdiom {
        case .phone:
            if let imageurl = event.podcast.artwork.thumb800Url {
                coverartView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .crossDissolve(0.2))
            }
        case .pad:
            if let imageurl = event.podcast.artwork.thumb3000Url {
                coverartView.af_setImageWithURL(imageurl, placeholderImage: nil, imageTransition: .crossDissolve(0.2))
            }
        default: break
        }
        
        updateFavoritesButton()
        
        // setup timer to update every minute
        // remember to invalidate timer as soon this view gets cleared otherwise
        // this will cause a memory cycle
        updateListenersTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateListenersLabel), userInfo: nil, repeats: true)
        updateListenersLabel()
        
        // hide these elements as long as HLS is not supported
        currentTimeLabel.isHidden = true
        timeLeftLabel.isHidden = true
        slider.isHidden = true
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        cleanupObservers()
        player = nil
        sleepTimer?.invalidate()
        updateListenersTimer?.invalidate()
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
    
    // MARK: - Actions
    
    @IBAction func toggleFavorite(_ sender: AnyObject) {
        if let event = event {
            Favorites.toggle(podcastId: event.podcast.id)
        }
    }
    
    @IBAction func share(_ sender: AnyObject) {
        if let url = event?.eventXenimWebUrl {
            let objectsToShare = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = shareButton
                
            // Excluded Activities
            //      activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePlayPause(_ sender: AnyObject) {
        if player.status != .failed {
            switch player.timeControlStatus {
            case .paused: player.play()
            case .playing: player.pause()
            case .waitingToPlayAtSpecifiedRate: break
            }
        }
    }
    
    @IBAction func backwardPressed(_ sender: AnyObject) {
        let timeBack = CMTimeMakeWithSeconds(30,1)
        player.seek(to: CMTimeSubtract(player.currentTime(), timeBack))
    }
    
    @IBAction func forwardPressed(_ sender: AnyObject) {
        let timeBack = CMTimeMakeWithSeconds(30,1)
        player.seek(to: CMTimeAdd(player.currentTime(), timeBack))
    }
    
    func updateFavoritesButton() {
        if let event = event {
            updateFavoritesButton(Favorites.isFavorite(event.podcast.id))
        }
    }
    
    private func updateFavoritesButton(_ isFavorite: Bool) {
        if isFavorite {
            favoriteButton.image = UIImage(named: "star_25")
            favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_is_favorite", value: "is favorite", comment: "")
        } else {
            favoriteButton.image = UIImage(named: "star_o_25")
            favoriteButton?.accessibilityValue = NSLocalizedString("voiceover_favorite_button_value_no_favorite", value: "is no favorite", comment: "")
        }
        
        // update command center like button state
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.likeCommand.isActive = isFavorite
        commandCenter.dislikeCommand.isActive = !isFavorite
    }
    
    func showInfoMessage(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showStreamErrorMessage(_ errorMessage: String? = nil) {
        let errorTitle = NSLocalizedString("player_failed_state_alertview_title", value: "Playback Error", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the title.")
        let defaultErrorMessage = NSLocalizedString("player_failed_state_alertview_message", value: "The selected stream can not be played.", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the message.")
        if let error = player.error?.localizedDescription {
            showInfoMessage(errorTitle, message: error)
        } else if let message = errorMessage {
            showInfoMessage(errorTitle, message: message)
        } else {
            showInfoMessage(errorTitle, message: defaultErrorMessage)
        }
        
    }
    
    private func showPlaybuttonPlaying() {
        loadingSpinnerView.isHidden = true
        playPauseButton?.setImage(UIImage(named: "large-pause"), for: UIControlState())
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_playing", value: "playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_playing", value: "double tap to pause", comment: "")
    }
    
    private func showPlaybuttonPaused() {
        loadingSpinnerView.isHidden = true
        playPauseButton?.setImage(UIImage(named: "large-play"), for: UIControlState())
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_not_playing", value: "not playing", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_not_playing", value: "double tap to play", comment: "")
    }
    
    private func showPlaybuttonBuffering() {
        loadingSpinnerView.isHidden = false
        playPauseButton?.setImage(UIImage(named: "large-pause"), for: UIControlState())
        playPauseButton.accessibilityValue = NSLocalizedString("voiceover_playbutton_value_buffering", value: "buffering", comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("voiceover_playbutton_hint_buffering", value: "double tap to pause", comment: "")
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch { }
    }
    
    private func setupPlayerAndPlay() {
        if let streamURL = event.streams.first?.url {
            player = AVPlayer()
            
            setupObservers()
            setupAudioSession()
            
            let asset = AVAsset(url: streamURL)
            let playerItem = AVPlayerItem(asset: asset)
            player.play() // call play before setting the item is best practise from Apple
            player.replaceCurrentItem(with: playerItem)
            
            setupRemoteTransportControls()
        } else {
            showStreamErrorMessage()
        }
    }
    
    
    /**
     * adding basic info to the control center
     * @return {[type]} [description]
     */
    private func updateNowPlayingInfo() {
        var info = [String: AnyObject]()
        
        // show failed or buffering as the audio title to communicate the
        // player state to the lockscreen. if the audio is playing show the correct
        // item title
        var statusString = event.title
        if player.status == .failed {
            statusString = "failed"
        } else if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            statusString = "buffering"
        }
        info[MPMediaItemPropertyTitle] = statusString
        
        info[MPMediaItemPropertyArtist] = event.podcast.name
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.timeControlStatus == .playing ? 1 : 0
        if let image = coverartView.image {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        } else {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: UIImage(named: "iTunesArtwork")!)
        }
        // there is no realtime update of elapsed time required. only if playback position jumps.
        // the current time is automatically interpolated by the system according to the playback rate
        // so it only needs to be updated at the start and after seeking
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self.player.currentTime())
        if let item = player.currentItem {
            // if item duration can not be calculated as this is not HLS stream the info center will no show
            // the timeline as it does not make any sense
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(item.duration)
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.player.timeControlStatus == .playing {
                self.forwardPressed(self)
                return .success
            } else {
                return .commandFailed
            }
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.player.timeControlStatus == .playing {
                self.backwardPressed(self)
                return .success
            } else {
                return .commandFailed
            }
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.player.play()
            return .success
//            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.togglePlayPause(self)
            return .success
        }
        
        
        // setup like and dislike command
        // problem: if I use this, seeking backwards is not displayed any more
        commandCenter.likeCommand.localizedTitle = "Favorite"
        commandCenter.likeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.toggleFavorite(self)
            return .success
        }
        
        commandCenter.dislikeCommand.localizedTitle = "No Favorite"
        commandCenter.dislikeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.toggleFavorite(self)
            return .success
        }
        // set the like status to the current state of the podcast
        commandCenter.likeCommand.isActive = Favorites.isFavorite(event.podcast.id)
        commandCenter.dislikeCommand.isActive = !Favorites.isFavorite(event.podcast.id)
        
        // there is some command center code for liking in the update favorites button code
        
    }
    
    // MARK: - update listeners timer
    
    @objc func updateListenersLabel() {
        event.fetchCurrentListeners { (listeners) -> Void in
            if let listeners = listeners {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.listenersCountButton.setTitle("\(listeners)", for: UIControlState())
                })
            }
        }
    }
    
    // MARK: - sleeptimer
    
    private var sleepTimerTicksLeft: Int?
    private weak var sleepTimer: Timer?
    
    @IBAction func sleepTimerPressed(_ sender: AnyObject) {
        if sleepTimer != nil {
            disableSleepTimer()
        } else {
            // show action sheet to select time
            // 10, 20, 30, 60 minutes
            
            let optionMenu = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            
            optionMenu.view.tintColor = Constants.Colors.tintColor
            
            for minutes in [10, 20, 30, 60] {
                let action = UIAlertAction(title: "\(minutes)min", style: .default, handler: { (alert: UIAlertAction!) -> Void in
                    self.enableSleepTimer(minutes: minutes)
                })
                optionMenu.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: "Cancel"), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(cancelAction)
            optionMenu.popoverPresentationController?.sourceView = sleepTimerButton
            
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    private func enableSleepTimer(minutes: Int) {
        let oneMinute: TimeInterval = 60
        sleepTimer = Timer.scheduledTimer(timeInterval: oneMinute, target: self, selector: #selector(sleepTimerTriggered), userInfo: nil, repeats: true)
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
            player.pause()
        }
        updateSleepTimerDisplay()
    }
    
    private func updateSleepTimerDisplay() {
        if let minutesLeft = sleepTimerTicksLeft {
            sleepTimerButton.setTitle("\(minutesLeft)min", for: UIControlState())
            
            sleepTimerButton.accessibilityValue = String.localizedStringWithFormat(NSLocalizedString("voiceover_sleep_button_value", value: "%@ minutes left", comment: ""), "\(minutesLeft)")
            sleepTimerButton.accessibilityHint = NSLocalizedString("voiceover_sleep_button_hint_disable", value: "Double Tap to disable the sleep timer", comment: "")
        } else {
            sleepTimerButton.setTitle("", for: UIControlState())
            sleepTimerButton.accessibilityValue = NSLocalizedString("voiceover_sleep_button_value_disabled", value: "disabled", comment: "")
            sleepTimerButton.accessibilityHint = NSLocalizedString("voiceover_sleep_button_hint_configure", value: "double tap to configure a sleep timer", comment: "")
        }
        
    }
    
    // MARK: audio session
    
    /**
     Audio session got interrupted by the system (call, Siri, ...). If interruption begins,
     we should ensure the audio pauses and if it ends, we should restart playing if state was
     `.Playing` before.
     - parameter note: The notification information.
     */
    @objc private func audioSessionGotInterrupted(note: NSNotification) {

        guard let userInfo = note.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            // Interruption began, take appropriate actions
            player.pause()
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
                if options == .shouldResume {
                    // Interruption Ended - playback should resume
                    setupAudioSession()
                    player.play()
                } else {
                    // Interruption Ended - playback should NOT resume
                    // just keep the player paused
                }
            }
        }
    }
    
    /**
     Audio session route changed (ex: earbuds plugged in/out). This can change the player
     state, so we just adapt it.
     - parameter note: The notification information.
     */
    @objc private func audioSessionRouteChanged(note: NSNotification) {
        
    }
    
    /**
     Audio session got messed up (media services lost or reset). We gotta reactive the
     audio session and reset player.
     - parameter note: The notification information.
     */
    @objc private func audioSessionMessedUp(note: NSNotification) {
        cleanupObservers()
        player = nil
        setupPlayerAndPlay()
    }
    
    
    // MARK: - observers
    
    override func canBecomeFirstResponder() -> Bool { return true }
    override func canResignFirstResponder() -> Bool { return true }
    
    private func setupObservers() {
        // timeControlStatus tells me if the player is currently playing or not
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: &observerContext)
        // status tells me if the playback failed completly for some reason
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new], context: &observerContext)
        // use a time observer for timing based status like current playback time
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main, using: { (time: CMTime) in
            let (currentTimeMinutes, currentTimeSeconds) = self.player.currentTime().humanReadable()
            self.currentTimeLabel.text = "\(currentTimeMinutes):\(currentTimeSeconds)"
            if let item = self.player.currentItem {
                let (durationMinutes, durationSeconds) = item.duration.humanReadable()
                self.timeLeftLabel.text = "\(durationMinutes):\(durationSeconds)"
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.favoriteAdded(_:)), name: Favorites.favoriteAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.favoriteRemoved(_:)), name: Favorites.favoriteRemovedNotification, object: nil)

        // be notified if the audio session is interrupted or crashed
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.audioSessionGotInterrupted(note:)), name: Notification.Name("AVAudioSessionInterruptionNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.audioSessionRouteChanged(note:)), name: Notification.Name("AVAudioSessionRouteChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.audioSessionMessedUp(note:)), name: Notification.Name("AVAudioSessionMediaServicesWereLostNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.audioSessionMessedUp(note:)), name: Notification.Name("AVAudioSessionMediaServicesWereResetNotification"), object: nil)
        
        // player item notifications
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.itemDidPlayToEndTime(note:)), name: Notification.Name("AVPlayerItemDidPlayToEndTimeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.itemFailedToPlayToEndTime(note:)), name: Notification.Name("AVPlayerItemFailedToPlayToEndTimeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.itemPlaybackStalled(note:)), name: Notification.Name("AVPlayerItemPlaybackStalledNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.itemNewErrorLogEntry(note:)), name: Notification.Name("AVPlayerItemNewErrorLogEntryNotification"), object: nil)
    }
    
    private func cleanupObservers() {
        NotificationCenter.default.removeObserver(self)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: &observerContext)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &observerContext)
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
    
    // this is called on any KVO update
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        // check if it is my context
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        updateNowPlayingInfo()
        
        // check for the different KVO changes I am interested in
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            switch player.timeControlStatus {
            case .paused: showPlaybuttonPaused()
            case .playing: showPlaybuttonPlaying()
            case .waitingToPlayAtSpecifiedRate: showPlaybuttonBuffering()
            }
        } else if keyPath == #keyPath(AVPlayer.status) {
            switch player.status {
            case .failed:
                showPlaybuttonPaused()
                showStreamErrorMessage()
            case .unknown:
                showPlaybuttonPaused()
                showStreamErrorMessage()
            case .readyToPlay: break
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func favoriteAdded(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            if podcastId == event.podcast.id {
                updateFavoritesButton(true)
            }
        }
    }
    
    func favoriteRemoved(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo, let podcastId = userInfo["podcastId"] as? String {
            if podcastId == event.podcast.id {
                updateFavoritesButton(false)
            }
        }
    }
    
    @objc private func itemDidPlayToEndTime(note: Notification) {
        // stream ended, so we close the player
        self.performSegue(withIdentifier: "dismissPlayer", sender: self)
    }
    
    @objc private func itemFailedToPlayToEndTime(note: Notification) {
        showStreamErrorMessage()
    }
    
    @objc private func itemPlaybackStalled(note: Notification) {
        showStreamErrorMessage("Did not receive enough data. Trying to recover.")
    }
    
    @objc private func itemNewErrorLogEntry(note: Notification) {
        
    }
    
}
