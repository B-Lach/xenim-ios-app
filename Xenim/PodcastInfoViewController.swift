//
//  PodcastInfoViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastInfoViewController: UIViewController {
    
    weak var statusBarStyleDelegate: StatusBarDelegate!
    weak var pageViewDelegate: PageViewDelegate!
    
    var event: Event! {
        didSet {
            updateUI()
        }
    }

    @IBOutlet weak var topbarView: UIView!
    @IBOutlet weak var coverartImageView: UIImageView! {
        didSet {
            coverartImageView.layer.cornerRadius = coverartImageView.frame.width / 2
            coverartImageView.layer.masksToBounds = true
            coverartImageView.layer.borderColor =  UIColor.lightGrayColor().CGColor
            coverartImageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.originalUrl {
            coverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        }
        podcastNameLabel?.text = event.podcast.name
        podcastDescriptionLabel?.text = event.podcast.podcastDescription
        eventTitleLabel?.text = event.title
        updateFavoriteButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.LightContent)
    }
    
    func updateFavoriteButton() {
        if Favorites.fetch().contains(event.podcast.id) {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
        } else {
            favoriteButton?.setImage(UIImage(named: "scarlet-44-star-o"), forState: .Normal)
        }
    }
    
    // MARK: Actions
    
    @IBAction func backToPlayer(sender: AnyObject) {
        pageViewDelegate.showPage(0)
    }
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        Favorites.toggle(podcastId: event.podcast.id)
    }

    @IBAction func subscribe(sender: AnyObject) {
    }
    
    
    // MARK: notifications
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventDetailViewController.favoriteAdded(_:)), name: "favoriteAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventDetailViewController.favoriteRemoved(_:)), name: "favoriteRemoved", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func favoriteAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
                favoriteButton?.setImage(UIImage(named: "scarlet-44-star"), forState: .Normal)
                animateFavoriteButton()
            }
        }
    }
    
    func favoriteRemoved(notification: NSNotification) {
        if let userInfo = notification.userInfo, let podcastId = userInfo["podcastId"] as? String {
            // check if this affects this cell
            if podcastId == event.podcast.id {
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
