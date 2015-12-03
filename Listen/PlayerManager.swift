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

class PlayerManager : NSObject, AudioPlayerDelegate {
    
    static let sharedInstance = PlayerManager()
    
    var event: Event?
    var player = AudioPlayer()
    var currentItem: AudioItem?
    
    override init() {
        super.init()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        player.delegate = self
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
//        print("\(from) -> \(to)")
        NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": self])
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {}
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {}
    
    private func playEvent(event: Event) {
        self.event = event
        
        currentItem = AudioItem(mediumQualitySoundURL: event.streamurl)
        currentItem?.artist = event.podcastDescription
        currentItem?.title = event.title
        player.playItem(currentItem!)

        // fetch coverart from image cache and set it as lockscreen artwork
        Alamofire.request(.GET, event.imageurl)
            .responseImage { response in
                if let image = response.result.value {
                    self.currentItem?.artworkImage = image
                }
        }
    }
    
    func stop() {
        player.stop()
        event = nil
        currentItem = nil
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
    
    func plus30seconds() {
        let currentTime = player.currentItemProgression
        let newTime = currentTime?.advancedBy(30)
        player.seekToTime(newTime!)
    }
    
    func minus30seconds() {
        let currentTime = player.currentItemProgression
        let newTime = currentTime?.advancedBy(-30)
        player.seekToTime(newTime!)
    }
    
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
                if let event = self.event {
                    togglePlayPause(event)
                }
            default:
                break
            }
        }
    }
}
