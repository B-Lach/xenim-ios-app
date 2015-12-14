//
//  Player.swift
//  Listen
//
//  Created by Stefan Trauth on 09/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import MediaPlayer
import Alamofire
import KDEAudioPlayer
import UIKit

class PlayerManager : NSObject, AudioPlayerDelegate, PlayerManagerDelegate {
    
    static let sharedInstance = PlayerManager()
    
    var event: Event?
    var player = AudioPlayer()
    var currentItem: AudioItem?
    var playerViewController: PlayerViewController?
    private var baseViewController: UIViewController?
    
    // MARK: - init
    
    override init() {
        super.init()
        baseViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        player.delegate = self
    }
    
    // MARK: - Actions
    
    func stop() {
        player.stop()
        event = nil
        currentItem = nil
    }
    
    // MARK: Delegate
    
    func longPress() {
        if !(baseViewController?.presentedViewController is UIAlertController) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.view.tintColor = Constants.Colors.tintColor
            let endPlayback = NSLocalizedString("player_manager_actionsheet_end_playback", value: "End Playback", comment: "long pressing in the player view shows an action sheet to end playback. this is the action message to end playback.")
            alert.addAction(UIAlertAction(title: endPlayback, style: UIAlertActionStyle.Destructive, handler: { (_) -> Void in
                // dissmiss the action sheet
                self.baseViewController?.dismissViewControllerAnimated(true, completion: nil)
                self.stop()
            }))
            let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel")
            alert.addAction(UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel, handler: nil))
            baseViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func togglePlayPause(event: Event) {
        // if it is a new event
        if event != self.event {
            playEvent(event)
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
    
    func sharePressed() {
        let toShare = NSURL(string: "http://www.codingexplorer.com/")!
        let objectsToShare = [toShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        
        // Excluded Activities
//      activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
        
        baseViewController?.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    // MARK: private
    
    private func showInfoMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = Constants.Colors.tintColor
        let dismiss = NSLocalizedString("dismiss", value: "Dismiss", comment: "Dismiss")
        alert.addAction(UIAlertAction(title: dismiss, style: UIAlertActionStyle.Cancel, handler: nil))
        baseViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func playEvent(event: Event) {
        self.event = event
        
        if playerViewController == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            playerViewController = storyboard.instantiateViewControllerWithIdentifier("AudioPlayerController") as? PlayerViewController
            playerViewController!.playerManagerDelegate = self
        }
        
        let longpressRecognizer = UILongPressGestureRecognizer(target: playerViewController, action: "handleLongPress:")
        longpressRecognizer.delegate = playerViewController
        
        playerViewController!.event = event
        
        baseViewController?.presentPopupBarWithContentViewController(playerViewController!, animated: true, completion: nil)
        baseViewController?.popupBar.addGestureRecognizer(longpressRecognizer)
        
        currentItem = AudioItem(mediumQualitySoundURL: event.streamurl)
        currentItem?.artist = event.podcastDescription
        currentItem?.title = event.title
        player.playItem(currentItem!)
        
        // fetch coverart from image cache and set it as lockscreen artwork
        if let imageurl = event.imageurl {
            Alamofire.request(.GET, imageurl)
                .responseImage { response in
                    if let image = response.result.value {
                        self.currentItem?.artworkImage = image
                    }
            }
        }
    }
    
    private func plus30seconds() {
        let currentTime = player.currentItemProgression
        let newTime = currentTime?.advancedBy(30)
        player.seekToTime(newTime!)
    }
    
    private func minus30seconds() {
        let currentTime = player.currentItemProgression
        let newTime = currentTime?.advancedBy(-30)
        player.seekToTime(newTime!)
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
            let errorTitle = NSLocalizedString("player_failed_state_alertview_title", value: "Playback Error", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the title.")
            let errorMessage = NSLocalizedString("player_failed_state_alertview_message", value: "The selected stream can not be played.", comment: "If a stream can not be played and the player goes to failed state this error message alert view will be displayed. this is the message.")
            showInfoMessage(errorTitle, message: errorMessage)
            // .Stopped will be the next state automatically
            // this will dismiss the player
        }
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {}
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {}
    
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
