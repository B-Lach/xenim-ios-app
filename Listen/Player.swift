//
//  Player.swift
//  Listen
//
//  Created by Stefan Trauth on 09/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import MediaPlayer
import Haneke

class Player : NSObject {
    
    static let sharedInstance = Player()
    
    var event: Event?
    var isPlaying:Bool {
        get {
            // rate is always between 0 and 1
            // a rate greater than 0 means its playing
            return player.rate > 0
        }
    }
    var player = AVPlayer()
    
    override init() {
        super.init()
        player = AVPlayer()
        player.addObserver(self, forKeyPath: "rate", options: .New, context: nil)
        // required to play audio in background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {}
        setupRemoteCommands()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        player.removeObserver(self, forKeyPath: "rate")
    }
    
    private func playEvent(event: Event) {
        self.event = event
        let playerItem = AVPlayerItem(URL: event.streamurl)
        player.replaceCurrentItemWithPlayerItem(playerItem)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        player.play()
        // fetch coverart from image cache and set it as lockscreen artwork
        let imageCache = Shared.imageCache
        imageCache.fetch(URL: event.imageurl).onSuccess { (image) -> () in
            let songInfo: Dictionary = [
                MPMediaItemPropertyTitle: self.event!.title,
                MPMediaItemPropertyArtist: self.event!.podcastDescription,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notify:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notify:", name: "AVPlayerItemFailedToPlayToEndTimeNotification", object: player.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notify:", name: "AVPlayerItemPlaybackStalledNotification", object: player.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notify:", name: "AVPlayerItemNewErrorLogEntryNotification", object: player.currentItem)
        
        NSNotificationCenter.defaultCenter().postNotificationName("playerRateChanged", object: player, userInfo: ["player": self])
    }
    
    func notify(notification: NSNotification) {
        print("notification")
        if let playerItem = player.currentItem {
            switch playerItem.status {
            case AVPlayerItemStatus.Failed:
                print("failed")
            default:
                print("default")
            }
        }
    }
    
    func togglePlayPause(event: Event) {
        // if it is a new event
        if event != self.event {
            playEvent(event)
        } else {
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
        }
    }
    
    @objc func togglePlayPause() {
        togglePlayPause(event!)
    }
    
    func setupRemoteCommands() {
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.togglePlayPauseCommand.addTarget(self, action: Selector("togglePlayPause"))
        commandCenter.togglePlayPauseCommand.enabled = true
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "rate" {
            NSNotificationCenter.defaultCenter().postNotificationName("playerRateChanged", object: player, userInfo: ["player": self])
        }
    }
}
