//
//  FavoriteDetailViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 16/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class FavoriteDetailViewController: UIViewController {
    
    var podcast: Podcast!

    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nextDateLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = podcast.artwork.thumb180Url{
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        
        podcastNameLabel.text = podcast.name
        subtitleLabel.text = podcast.subtitle
        podcastDescriptionLabel.text = podcast.podcastDescription
        
        updateNextDateLabel()
        updateFavoriteButton()
        
        setupToolbar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupToolbar() {
        var items = [UIBarButtonItem]()
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        if podcast.websiteUrl != nil {
            let websiteBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-safari"), style: .Plain, target: self, action: "openWebsite")
            items.append(websiteBarButton)
            items.append(space)
        }
        
        if podcast.twitterURL != nil {
            let twitterBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-twitter-square"), style: .Plain, target: self, action: "openTwitter")
            items.append(twitterBarButton)
            items.append(space)
        }
        
        if podcast.feedUrl != nil {
            let subscribeBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-rss-square"), style: .Plain, target: self, action: "subscribe")
            items.append(subscribeBarButton)
            items.append(space)
        }
        
        if podcast.email != nil {
            let mailBarButton = UIBarButtonItem(image: UIImage(named: "scarlet-25-envelope"), style: .Plain, target: self, action: "sendMail")
            items.append(mailBarButton)
            items.append(space)
        }
        
        // more
        
        // last item should not be a space, so remove it then
        if items.last == space {
            items.removeLast()
        }
        
        toolbar.setItems(items, animated: true)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-25-star-o"), forState: .Normal)
        }
    }
    
    func updateNextDateLabel() {
        // TODO
    }
    
    // MARK: Actions
    
    func sendMail() {
        
    }
    
    func openWebsite() {
        
    }
    
    func openTwitter() {
        
    }
    
    func subscribe() {
        
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: podcast.id)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoritesChanged:"), name: "favoritesChanged", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoritesChanged(notification: NSNotification) {
        updateFavoriteButton()
    }

}
