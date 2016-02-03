//
//  PopupViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController, UIGestureRecognizerDelegate, UIPageViewControllerDataSource {

    var event: Event!
    let pageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
    let playerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlayerViewController") as! PlayerViewController
    let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController.setViewControllers([chatViewController], direction: .Forward, animated: false, completion: nil)
        pageViewController.dataSource = self
        
        playerViewController.event = event
        
        pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 40.0)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
    }
    
    // MARK: - init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // use this to add more controls on ipad interface
        //if UIScreen.mainScreen().traitCollection.userInterfaceIdiom == .Pad {
        
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "scarlet-25-pause"), style: .Plain, target: self, action: "togglePlayPause:")]
        
//        miniCoverartImageView.frame = CGRectMake(0, 0, 30, 30)
//        miniCoverartImageView.layer.cornerRadius = 5.0
//        miniCoverartImageView.layer.masksToBounds = true
//        
//        let popupItem = UIBarButtonItem(customView: miniCoverartImageView)
//        self.popupItem.leftBarButtonItems = [popupItem]
    }
    
    func togglePlayPause(sender: AnyObject) {
        PlayerManager.sharedInstance.togglePlayPause(event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
//        if !(baseViewController?.presentedViewController is UIAlertController) {
//            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
//            alert.view.tintColor = Constants.Colors.tintColor
//            let endPlayback = NSLocalizedString("player_manager_actionsheet_end_playback", value: "End Playback", comment: "long pressing in the player view shows an action sheet to end playback. this is the action message to end playback.")
//            alert.addAction(UIAlertAction(title: endPlayback, style: UIAlertActionStyle.Destructive, handler: { (_) -> Void in
//                // dissmiss the action sheet
//                self.baseViewController?.dismissViewControllerAnimated(true, completion: nil)
//                self.stop()
//            }))
//            let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel")
//            alert.addAction(UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel, handler: nil))
//            baseViewController?.presentViewController(alert, animated: true, completion: nil)
//        }
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
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case chatViewController:
            return playerViewController
        case playerViewController:
            return nil
        default:
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case playerViewController:
            return chatViewController
        case chatViewController:
            return nil
        default:
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 2
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }

}
