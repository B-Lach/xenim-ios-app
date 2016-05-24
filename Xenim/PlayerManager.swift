//
//  Player.swift
//  Xenim
//
//  Created by Stefan Trauth on 09/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import MediaPlayer
import Alamofire
import KDEAudioPlayer
import UIKit

class PlayerManager : NSObject, AudioPlayerDelegate {
    
    static let sharedInstance = PlayerManager()
    
    var event: Event?
    var player = AudioPlayer()
    var currentItem: AudioItem?
    private weak var baseViewController: UITabBarController?
    
    // MARK: - init
    
    override init() {
        super.init()
        let rootViewController = UIApplication.sharedApplication().keyWindow!.rootViewController! as! UITabBarController
        baseViewController = rootViewController
        player.delegate = self
    }
    
    // MARK: - Actions
    
    func stop() {
        player.stop()
        event = nil
        currentItem = nil
    }
    
    func togglePlayPause(event: Event) {
        // if it is a new event
        if event != self.event {
            playEvent(event)
            // fire this notification because if a new event is being played the player state
            // might not change (only from playing to playing) but the interface needs to update
            // to show the correct item as playing
            NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": self])
        } else {
            switch player.state {
            case .Buffering: break
            case .Paused:
                player.resume()
            case .Playing:
                player.pause()
            case .Stopped:
                player.playItem(currentItem!)
            case .WaitingForConnection: break
            case .Failed(_):
                player.playItem(currentItem!)
            }
        }
    }
    
    func forwardPressed() {
        plus30seconds()
    }
    
    func backwardPressed() {
        minus30seconds()
    }
    
    // MARK: private
    
    private func showStreamErrorMessage() {
        let errorTitle = NSLocalizedString("player_failed_state_alertview_title", value: "Playback Error", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the title.")
        let errorMessage = NSLocalizedString("player_failed_state_alertview_message", value: "The selected stream can not be played.", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the message.")
        showInfoMessage(errorTitle, message: errorMessage)
    }
    
    private func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        baseViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func playEvent(event: Event) {
        if let audioItem = AudioItem(mediumQualitySoundURL: event.streamUrl) {
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            
            self.event = event
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerViewController = storyboard.instantiateViewControllerWithIdentifier("PlayerViewController") as? PlayerViewController
            playerViewController!.presenter = baseViewController
            
            let longpressRecognizer = UILongPressGestureRecognizer(target: playerViewController, action: #selector(playerViewController?.handleLongPress(_:)))
            longpressRecognizer.delegate = playerViewController
            
            playerViewController!.event = event
            
            baseViewController?.presentPopupBarWithContentViewController(playerViewController!, openPopup: true, animated: true, completion: nil)
            baseViewController?.popupBar!.addGestureRecognizer(longpressRecognizer)
            baseViewController?.popupContentView.popupCloseButton!.hidden = true
            
            currentItem = audioItem
            currentItem?.artist = event.podcast.name
            currentItem?.title = event.title
            player.playItem(currentItem!) // save as this can not be nil
            
            // fetch coverart from image cache and set it as lockscreen artwork
            let screenScale = UIScreen.mainScreen().scale
            if event.podcast.artwork.thumb800Url != nil && screenScale <= 2 {
                Alamofire.request(.GET, event.podcast.artwork.thumb800Url!)
                    .responseImage { response in
                        if let image = response.result.value {
                            self.currentItem?.artworkImage = image
                        }
                }
            } else if event.podcast.artwork.thumb1300Url != nil && screenScale > 2 {
                Alamofire.request(.GET, event.podcast.artwork.thumb1300Url!)
                    .responseImage { response in
                        if let image = response.result.value {
                            self.currentItem?.artworkImage = image
                        }
                }
            }
            

        } else {
            showStreamErrorMessage()
        }
    }
    
    private func plus30seconds() {
        let currentTime = player.currentItemProgression
        if let newTime = currentTime?.advancedBy(30) {
            player.seekToTime(newTime)
        }
    }
    
    private func minus30seconds() {
        let currentTime = player.currentItemProgression
        if let newTime = currentTime?.advancedBy(-30) {
            player.seekToTime(newTime)
        }
    }
    
    // MARK: - Notifications
    
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        //        print("\(from) -> \(to)")
        NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": self])
        
        switch player.state {
        case .Buffering: break
        case .Paused: break
        case .Playing: break
        case .Stopped:
            // dismiss the player
            baseViewController?.dismissPopupBarAnimated(true, completion: nil)
        case .WaitingForConnection: break
        case .Failed(_):
            showStreamErrorMessage()
            // .Stopped will be the next state automatically
            // this will dismiss the player
        }
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {}
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange, forItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateEmptyMetadataOnItem item: AudioItem, withData data: Metadata) {}
    
    /**
     remote control event is received in app delegate and passed for processing here
    */
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == .RemoteControl {
            //ControlCenter Or Lock screen
            switch event.subtype {
            case .RemoteControlBeginSeekingBackward:
                break
            case .RemoteControlBeginSeekingForward:
                break
            case .RemoteControlEndSeekingBackward:
                break
            case .RemoteControlEndSeekingForward:
                break
            case .RemoteControlNextTrack:
                forwardPressed()
            case .RemoteControlPause:
                player.pause()
            case .RemoteControlPlay:
                player.resume()
            case .RemoteControlPreviousTrack:
                backwardPressed()
            case .RemoteControlStop:
                stop()
            case .RemoteControlTogglePlayPause:
                if let event = self.event {
                    togglePlayPause(event)
                }
            default:
                break
            }
        }
    }
}
