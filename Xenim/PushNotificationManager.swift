//
//  PushNotificationManager.swift
//  Xenim
//
//  Created by Stefan Trauth on 10/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import Parse

class PushNotificationManager {
    
    private static let PARSE_SERVER_URL = "https://dev.push.xenim.de/parse"
    
    static func setupPushNotifications() {
        
        // fetch parse keys from Keys.plist
        // this is force unwrapped intentionally. I want it to crash if this file is not working.
        let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path!)
        let applicationId = keys!["parseApplicationID"] as! String
        let clientKey = keys!["parseClientKey"] as! String
        
        Parse.initializeWithConfiguration(ParseClientConfiguration(block: { (config) -> Void in
            config.applicationId = applicationId
            config.clientKey = clientKey
            config.server = PARSE_SERVER_URL
        }))
        
        let application = UIApplication.sharedApplication()
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            let showInfoAction = UIMutableUserNotificationAction()
            showInfoAction.identifier = "SHOW_INFO_IDENTIFIER"
            showInfoAction.title = NSLocalizedString("push_notification_action_show_info", value: "Show Info", comment: "the title of the button in a push notification for the action to show info of the event")
            showInfoAction.activationMode = UIUserNotificationActivationMode.Foreground
            showInfoAction.destructive = false
            showInfoAction.authenticationRequired = false
            
            let listenNowAction = UIMutableUserNotificationAction()
            listenNowAction.identifier = "LISTEN_NOW_IDENTIFIER"
            listenNowAction.title = NSLocalizedString("push_notification_action_listen_now", value: "Listen Now", comment: "the title of the button in a push notification for the action to start streaming the event now")
            listenNowAction.activationMode = UIUserNotificationActivationMode.Foreground
            listenNowAction.destructive = false
            listenNowAction.authenticationRequired = false
            
            let eventNotificationCategory = UIMutableUserNotificationCategory()
            eventNotificationCategory.identifier = "EVENT_LIVE_NOW_CATEGORY"
            
            let defaultActions: NSArray = [showInfoAction, listenNowAction]
            let minimalActions: NSArray = [showInfoAction, listenNowAction]
            
            eventNotificationCategory.setActions(defaultActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Default)
            eventNotificationCategory.setActions(minimalActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Minimal)
            
            let categories:NSSet = NSSet(object: eventNotificationCategory)
            
            let types: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: categories as? Set<UIUserNotificationCategory>)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    static func subscribeToPodcastChannel(podcastId: String) {
        if podcastId != "" {
            let channel = "podcast_\(podcastId)"
            subscribeToChannel(channel)
        }
    }
    
    static func unsubscribeFromPodcastChannel(podcastId: String) {
        if podcastId != "" {
            let channel = "podcast_\(podcastId)"
            unsubscribeFromChannel(channel)
        }
    }
    
    static func subscribeToChannel(channel: String) {
        if channel != "" {
            let installation = PFInstallation.currentInstallation()
            installation.addUniqueObject(channel, forKey: "channels")
            installation.saveInBackground()
        }
    }
    
    static func unsubscribeFromChannel(channel: String) {
        if channel != "" {
            let installation = PFInstallation.currentInstallation()
            installation.removeObject(channel, forKey: "channels")
            installation.saveInBackground()
        }
    }
    
}