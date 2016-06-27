//
//  AppDelegate.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import Parse
//import AlamofireNetworkActivityIndicator

struct Constants {
    struct Colors {
        static let tintColor = UIColor(red:1.00, green:0.45, blue:0.39, alpha:1.00)
    }
    struct API {
        // "https://dev.push.xenim.de/parse"
        static let parseServer = "https://dev.push.xenim.de/parse"
        // "http://feeds.streams.demo.xenim.de/api/v1/"
        static let xenimApiUrl = "http://feeds.streams.demo.xenim.de/api/v2/"
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // the statusbar is hidden on launch, because it should not be visible on launchscreen
        // reenable it here
        application.isStatusBarHidden = false

        // alamofire requests show network indicator
//        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
//        NetworkActivityIndicatorManager.sharedManager.startDelay = 0.3
        
        // fetch parse keys from Keys.plist
        // this is force unwrapped intentionally. I want it to crash if this file is not working.
        let path = Bundle.main().pathForResource("Keys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path!)
        let applicationId = keys!["parseApplicationID"] as! String
        let clientKey = keys!["parseClientKey"] as! String
        
        Parse.initialize(with: ParseClientConfiguration(block: { (config) -> Void in
            config.applicationId = applicationId
            config.clientKey = clientKey
            // "https://dev.push.xenim.de/parse"
            config.server = Constants.API.parseServer
            config.isLocalDatastoreEnabled = true
        }))
        
        // register IAP handler. will be called when the item has been purchased.
        PFPurchase.addObserver(forProduct: "com.stefantrauth.XenimSupportSmall") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        PFPurchase.addObserver(forProduct: "com.stefantrauth.XenimSupportMiddle") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        PFPurchase.addObserver(forProduct: "com.stefantrauth.XenimSupportBig") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        setupPushNotifications()
        NotificationCenter.default().post(name: Notification.Name(rawValue: "refreshEvents"), object: nil, userInfo: nil)
        resetApplicationBadge(application)
    }
    
    func resetApplicationBadge(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation.setDeviceTokenFrom(deviceToken)
        installation.saveEventually()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handle(userInfo)
        NotificationCenter.default().post(name: Notification.Name(rawValue: "refreshEvents"), object: nil, userInfo: nil)
        resetApplicationBadge(application)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if let event = event {
//            PlayerManager.sharedInstance.remoteControlReceivedWithEvent(event)
        }
    }
    
    func setupPushNotifications() {
        let application = UIApplication.shared()
        let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
        let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }


}

