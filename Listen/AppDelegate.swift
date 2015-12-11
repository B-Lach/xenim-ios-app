//
//  AppDelegate.swift
//  Listen
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import Parse
import CRToast

struct Constants {
    struct Colors {
        static let tintColor = UIColor(red:0.98, green:0.18, blue:0.25, alpha:1)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        UINavigationBar.appearance().tintColor = Constants.Colors.tintColor
        UITabBar.appearance().tintColor = Constants.Colors.tintColor
//        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]

        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        resetApplicationBadge(application)
    }
    
    func resetApplicationBadge(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if ( application.applicationState == UIApplicationState.Active ) {
            // app was already in the foreground
            
            if let message = userInfo["aps"]?["alert"] as? String {
                let options: [NSObject:AnyObject] = [
                    kCRToastTextKey : message,
                    kCRToastTextAlignmentKey : NSTextAlignment.Center.rawValue,
                    kCRToastBackgroundColorKey : UIColor(red:0.01, green:0.44, blue:0.91, alpha:1),
                    kCRToastTextColorKey: UIColor.whiteColor(),
                    kCRToastTimeIntervalKey: NSTimeInterval(3)
                ]
                CRToastManager.showNotificationWithOptions(options, completionBlock: nil)
            }
            resetApplicationBadge(application)
        } else {
            // app was just brought from background to foreground because the user clicked on a notification
            showEventInfo(userInfo)
        }
    }
    
    /**
     This is called when a user clicks on a notifcation action button.
     registering for notification actions happens in PushNotificationManager.swift
    */
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
        if identifier == "SHOW_INFO_IDENTIFIER" {
            showEventInfo(userInfo)
        } else if identifier == "LISTEN_NOW_IDENTIFIER" {
            playEvent(userInfo)
        } else {
            // action clicked is unknown. ignore
        }
        
        completionHandler() // apple says you have to call this
    }
    
    func showEventInfo(userInfo: [NSObject : AnyObject]) {
        // Extract the notification event data
        if let eventId = userInfo["event_id"] as? String {
            print("show event info for: \(eventId)")
        }
    }
    
    func playEvent(userInfo: [NSObject : AnyObject]) {
        // Extract the notification event data
        if let eventId = userInfo["event_id"] as? String {
            print("play event \(eventId)")
            let event = Event(duration: "90", livedate: "2015-12-11 20:00:00", podcastSlug: "breitband", streamurl: "http://www.dradio.de/streaming/dkultur.m3u", imageurl: "http://www.deutschlandradiokultur.de/media/files/2/258cfe6db750912b0bb36410d2fdf775v1.jpg", podcastDescription: "Magazin für Medien und digitale Kultur, immer samstags 13:05 im Deutschlandradio Kultur", title: "Breitband", url: "http://www.deutschlandradio.de/weiterleitung-breitband-de.233.de.html")
            PlayerManager.sharedInstance.togglePlayPause(event!)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if let event = event {
            PlayerManager.sharedInstance.remoteControlReceivedWithEvent(event)
        }
    }


}

