//
//  EventDetailViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 15/01/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {
    
    var podcast: Podcast!

    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    
    var dismissHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = podcast.artwork.originalUrl{
            coverartImageView.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        } else {
            coverartImageView.image = placeholderImage
        }
        
        eventDescriptionTextView.text = podcast.podcastDescription
        updateFavoriteButton()

    }
    
    override func viewDidLayoutSubviews() {
        // ensure text view is scrolled to the top
        eventDescriptionTextView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
        //eventDescriptionTextView.setContentOffset(CGPointZero, animated: false)
        //eventDescriptionTextView.scrollRangeToVisible(NSMakeRange(0, 0))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillLayoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        // scale the popover
        view.layer.cornerRadius = 10.0
        view.bounds = CGRectMake(0, 0, screenSize.width * 0.75, 450)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
        }
    }
    
    // MARK: Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: podcast.id)
    }
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteAdded:"), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("favoriteRemoved:"), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func animateFavoriteButton() {
        favoriteButton.transform = CGAffineTransformMakeScale(1.3, 1.3)
        UIView.animateWithDuration(0.3,
            delay: 0,
            usingSpringWithDamping: 2,
            initialSpringVelocity: 1.0,
            options: [UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.favoriteButton.transform = CGAffineTransformIdentity
            }, completion: nil)
    }

    // MARK: - static global
    
    // if the info button in the player for a specific event is pressed
    // this table view controller should segue to the event detail view
    static func showEventInfo(event event: Event) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // configure event detail view controller as popup content
        let eventDetailVC = storyboard.instantiateViewControllerWithIdentifier("EventDetail") as! EventDetailViewController
        eventDetailVC.podcast = event.podcast
        
        let window = UIApplication.sharedApplication().delegate?.window!
        let modal = PathDynamicModal.show(modalView: eventDetailVC, inView: window!)
        
        eventDetailVC.dismissHandler = {[weak modal] in
            modal?.closeWithStraight()
            return
        }
    }
}
