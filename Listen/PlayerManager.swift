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
        player.delegate = self
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        
//        switch to {
//        case AudioPlayerState.Buffering:
//            print("buffering")
//        case AudioPlayerState.Paused:
//            print("paused")
//        case AudioPlayerState.Playing:
//            print("playing")
//        case AudioPlayerState.Stopped:
//            print("stopped")
//        case AudioPlayerState.WaitingForConnection:
//            print("waiting for connection")
//        }
        NSNotificationCenter.defaultCenter().postNotificationName("playerStateChanged", object: player, userInfo: ["player": self])
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem) {}
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {}
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {}
    
    private func playEvent(event: Event) {
        self.event = event
        
        currentItem = AudioItem(mediumQualitySoundURL: event.streamurl)
        currentItem?.artist = event.podcastSlug
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
    
    func togglePlayPause(event: Event) {
        // if it is a new event
        if event != self.event {
            playEvent(event)
        } else {
            switch player.state {
            case AudioPlayerState.Buffering: break
            case AudioPlayerState.Paused:
                player.playItem(currentItem!)
            case AudioPlayerState.Playing:
                player.pause()
            case AudioPlayerState.Stopped:
                // TODO
                break
            case AudioPlayerState.WaitingForConnection: break
            }
        }
    }
}
