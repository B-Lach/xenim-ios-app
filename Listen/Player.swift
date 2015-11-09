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
    
    var event: Event!
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
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }
    
    deinit {
        player.removeObserver(self, forKeyPath: "rate")
    }
    
    private func playEvent(event: Event) {
        self.event = event
        player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: event.streamurl))
        player.play()
        // fetch coverart from image cache and set it as lockscreen artwork
        let imageCache = Shared.imageCache
        imageCache.fetch(URL: event.imageurl).onSuccess { (image) -> () in
            let songInfo: Dictionary = [
                MPMediaItemPropertyTitle: self.event.title,
                MPMediaItemPropertyArtist: self.event.podcastDescription,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
            ]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "rate" {
            NSNotificationCenter.defaultCenter().postNotificationName("playerRateChanged", object: player, userInfo: ["player": self])
        }
    }
}
