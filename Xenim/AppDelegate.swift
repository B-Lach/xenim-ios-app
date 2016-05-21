//
//  AppDelegate.swift
//  Xenim
//
//  Created by Stefan Trauth on 19/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import Parse
import AlamofireNetworkActivityIndicator

#if SCREENSHOTS
import SimulatorStatusMagic
#endif

struct Constants {
    struct Colors {
        static let tintColor = UIColor(red:0.98, green:0.18, blue:0.25, alpha:1)
    }
    struct API {
        // "https://dev.push.xenim.de/parse"
        static let parseServer = "https://dev.push.xenim.de/parse"
        // "http://feeds.streams.demo.xenim.de/api/v1/"
        static let xenimApiUrl = "http://feeds.streams.demo.xenim.de/api/v1/"
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // the statusbar is hidden on launch, because it should not be visible on launchscreen
        // reenable it here
        application.statusBarHidden = false
        
        #if SCREENSHOTS
        SDStatusBarManager.sharedInstance().enableOverrides()
        #endif

        // alamofire requests show network indicator
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        NetworkActivityIndicatorManager.sharedManager.startDelay = 0.3
        
        // fetch parse keys from Keys.plist
        // this is force unwrapped intentionally. I want it to crash if this file is not working.
        let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path!)
        let applicationId = keys!["parseApplicationID"] as! String
        let clientKey = keys!["parseClientKey"] as! String
        
        Parse.initializeWithConfiguration(ParseClientConfiguration(block: { (config) -> Void in
            config.applicationId = applicationId
            config.clientKey = clientKey
            // "https://dev.push.xenim.de/parse"
            config.server = Constants.API.parseServer
            config.localDatastoreEnabled = true
        }))
        
        // register IAP handler. will be called when the item has been purchased.
        PFPurchase.addObserverForProduct("com.stefantrauth.XenimSupportSmall") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        PFPurchase.addObserverForProduct("com.stefantrauth.XenimSupportMiddle") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        PFPurchase.addObserverForProduct("com.stefantrauth.XenimSupportBig") { (transaction:SKPaymentTransaction) in
            print("purchase was successful.")
        }
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        setupPushNotifications()
        NSNotificationCenter.defaultCenter().postNotificationName("refreshEvents", object: nil, userInfo: nil)
        resetApplicationBadge(application)
        
        // show donation hint if the app was used for quite some time
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var launchCount = userDefaults.integerForKey("launchCount") // returns 0 if key does not exist yet
        launchCount = launchCount + 1
        userDefaults.setInteger(launchCount, forKey: "launchCount")
        userDefaults.synchronize()
        
        // only show the alert ONE time after quite some app launches
        if launchCount == 50 {
            
            let dismissString = NSLocalizedString("dismiss", value: "Dismiss", comment: "dismiss")
            let donateString = NSLocalizedString("donate", value: "Donate", comment: "donate")
            let supportAlertTitle = NSLocalizedString("support_alert_title", value: "Please Support the Development", comment: "")
            let supportAlertMessage = NSLocalizedString("support_alert_message", value: "Do you like the app? Please consider supporting me with a small donation. If you do not want to donate now, you can always find the possibility in the settings.\n\nYou only see this message this one time and I will never bother you again.", comment: "")
            
            let alert = UIAlertController(title: supportAlertTitle, message: supportAlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: donateString, style: .Default, handler: { (action: UIAlertAction) in
                dispatch_async(dispatch_get_main_queue(), {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let settingsViewController = storyboard.instantiateViewControllerWithIdentifier("Settings") as? UINavigationController {
                        self.window?.rootViewController?.presentViewController(settingsViewController, animated: true, completion: nil)
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: dismissString, style: .Cancel, handler: nil))
                
            dispatch_async(dispatch_get_main_queue(), {
                self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
            })
        }
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

