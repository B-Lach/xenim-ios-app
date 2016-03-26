//
//  AppDelegate.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import Parse

struct Constants {
    struct Colors {
        static let tintColor = UIColor(red:0.98, green:0.18, blue:0.25, alpha:1)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // fetch parse keys from Keys.plist
        // this is force unwrapped intentionally. I want it to crash if this file is not working.
        let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path!)
        let applicationId = keys!["parseApplicationID"] as! String
        let clientKey = keys!["parseClientKey"] as! String
        
        Parse.initializeWithConfiguration(ParseClientConfiguration(block: { (config) -> Void in
            config.applicationId = applicationId
            config.clientKey = clientKey
            config.server = "https://dev.push.xenim.de/parse"
            config.localDatastoreEnabled = true
        }))
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        setupPushNotifications()
        NSNotificationCenter.defaultCenter().postNotificationName("refreshEvents", object: nil, userInfo: nil)
        resetApplicationBadge(application)
    }
    
    func resetApplicationBadge(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveEventually()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshEvents", object: nil, userInfo: nil)
        resetApplicationBadge(application)
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
    
    func setupPushNotifications() {
        let application = UIApplication.sharedApplication()
        let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }


}

