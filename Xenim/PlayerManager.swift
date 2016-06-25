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
    
    // MARK: - init
    
    override init() {
        super.init()
        player.delegate = self
    }
    
    // MARK: - Actions
    
    func stop() {
        player.stop()
        event = nil
        currentItem = nil
    }
    
    func togglePlayPause() {
        if currentItem != nil {
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
    
    func pause() {
        player.pause()
    }
    
    func play(event: Event) {
        if let audioItem = AudioItem(mediumQualitySoundURL: event.streamUrl) {
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            
            currentItem = audioItem
            currentItem?.artist = event.podcast.name
            currentItem?.title = event.title
            player.playItem(currentItem!) // save as this can not be nil
            
            // fetch coverart from image cache and set it as lockscreen artwork
            switch UIDevice.currentDevice().userInterfaceIdiom {
            case .Phone:
                if let imageurl = event.podcast.artwork.thumb800Url {
                    Alamofire.request(.GET, imageurl)
                        .responseImage { response in
                            if let image = response.result.value {
                                self.currentItem?.artworkImage = image
                            }
                    }
                }
            case .Pad:
                if let imageurl = event.podcast.artwork.thumb3000Url {
                    Alamofire.request(.GET, imageurl)
                        .responseImage { response in
                            if let image = response.result.value {
                                self.currentItem?.artworkImage = image
                            }
                    }
                }
            default: break
            }

        } else {
            stop()
            NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": self.player])
        }
    }
    
    
    func plus30seconds() {
        let currentTime = player.currentItemProgression
        if let newTime = currentTime?.advancedBy(30) {
            player.seekToTime(newTime)
        }
    }
    
    func minus30seconds() {
        let currentTime = player.currentItemProgression
        if let newTime = currentTime?.advancedBy(-30) {
            player.seekToTime(newTime)
        }
    }

    
    // MARK: private
    
    // MARK: - Notifications
    
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        //        print("\(from) -> \(to)")
        NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": audioPlayer])
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
                plus30seconds()
            case .RemoteControlPause:
                player.pause()
            case .RemoteControlPlay:
                player.resume()
            case .RemoteControlPreviousTrack:
                minus30seconds()
            case .RemoteControlStop:
                stop()
            case .RemoteControlTogglePlayPause:
                togglePlayPause()
            default:
                break
            }
        }
    }
}
