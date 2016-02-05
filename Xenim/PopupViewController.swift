//
//  PopupViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

protocol StatusBarDelegate {
    func updateStatusBarStyle(style: UIStatusBarStyle)
}

protocol PageViewDelegate {
    func showPage(index: Int)
}

class PopupViewController: UIViewController, UIGestureRecognizerDelegate, UIPageViewControllerDataSource, StatusBarDelegate, PageViewDelegate {

    var event: Event!
    let pageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
    
    let playerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlayerViewController") as! PlayerViewController
    var chatContainerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatContainerViewController") as! ChatContainerViewController
    
    var infoViewController: UINavigationController!
    
    var miniCoverartImageView: UIImageView!
    
    var statusBarStyle = UIStatusBarStyle.Default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let podcastInfoViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PodcastInfoViewController") as! PodcastInfoViewController
        
        playerViewController.event = event
        chatContainerViewController.event = event
        podcastInfoViewController.event = event
        
        pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 40.0)
        pageViewController.setViewControllers([playerViewController], direction: .Forward, animated: false, completion: nil)
        pageViewController.dataSource = self
        
        playerViewController.statusBarStyleDelegate = self
        chatContainerViewController.statusBarStyleDelegate = self
        podcastInfoViewController.statusBarStyleDelegate = self
        
        playerViewController.pageViewDelegate = self
        chatContainerViewController.pageViewDelegate = self
        podcastInfoViewController.pageViewDelegate = self
        
        infoViewController = UINavigationController(rootViewController: podcastInfoViewController)
        
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
        let title = event.title != nil ? event.title : event.podcast.name
        let description = event.eventDescription != nil ? event.eventDescription : event.podcast.podcastDescription
        
        popupItem.title = title
        popupItem.subtitle = description
        if let imageurl = event.podcast.artwork.thumb150Url {
            miniCoverartImageView.af_setImageWithURL(imageurl, placeholderImage: UIImage(named: "event_placeholder"), imageTransition: .CrossDissolve(0.2))
        }
        
        setupNotifications()
    }
    
    // MARK: - init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // use this to add more controls on ipad interface
        //if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {
        
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
        
        miniCoverartImageView = UIImageView(image: UIImage(named: "event_placeholder"))
        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
        miniCoverartImageView.layer.cornerRadius = 5.0
        miniCoverartImageView.layer.masksToBounds = true

        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
        self.popupItem.leftBarButtonItems = [popupItem]
    }
    
    func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
    
    func updateStatusBarStyle(style: UIStatusBarStyle) {
        statusBarStyle = style
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK: - delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let baseViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.view.tintColor = Constants.Colors.tintColor
        let endPlayback = NSLocalizedString("player_manager_actionsheet_end_playback", value: "End Playback", comment: "long pressing in the player view shows an action sheet to end playback. this is the action message to end playback.")
        alert.addAction(UIAlertAction(title: endPlayback, style: UIAlertActionStyle.Destructive, handler: { (_) -> Void in
            // dissmiss the action sheet
            baseViewController!.dismissViewControllerAnimated(true, completion: nil)
            PlayerManager.sharedInstance.stop()
        }))
        let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel")
        alert.addAction(UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel, handler: nil))
        baseViewController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStateChanged:"), name: "playerStateChanged", object: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerStateChanged(notification: NSNotification) {
        let player = PlayerManager.sharedInstance.player
        
        switch player.state {
        case .Buffering:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
        case .Paused:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: "togglePlayPause:")]
        case .Playing:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
        case .Stopped:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: "togglePlayPause:")]
        case .WaitingForConnection:
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
        case .Failed(_):
            self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-play"), style: .Plain, target: self, action: "togglePlayPause:")]
        }
    }
    
    // MARK: - Page View Controller Data Source
    
    // ORDER is: chatViewController, playerViewController, infoViewController
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case chatContainerViewController:
            return playerViewController
        case playerViewController:
            return infoViewController
        default:
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case playerViewController:
            return chatContainerViewController
        case infoViewController:
            return playerViewController
        default:
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 3
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func showPage(index: Int) {
        switch index {
        case 0:
            pageViewController.setViewControllers([chatContainerViewController], direction: .Reverse, animated: true, completion: nil)
        case 1:
            switch pageViewController.viewControllers!.last! {
            case chatContainerViewController:
                pageViewController.setViewControllers([playerViewController], direction: .Forward, animated: true, completion: nil)
            case infoViewController:
                pageViewController.setViewControllers([playerViewController], direction: .Reverse, animated: true, completion: nil)
            default: break
            }

        case 2:
            pageViewController.setViewControllers([infoViewController], direction: .Forward, animated: true, completion: nil)
        default: break
        }
    }

}
