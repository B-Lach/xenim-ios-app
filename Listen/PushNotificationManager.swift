//
//  PushNotificationManager.swift
//  Listen
//
//  Created by Stefan Trauth on 10/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import Parse

class PushNotificationManager {
    
    static func setupPushNotifications() {
        
        // fetch parse keys from Keys.plist
        // this is force unwrapped intentionally. I want it to crash if this file is not working.
        let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")
        let keys = NSDictionary(contentsOfFile: path!)
        let applicationId = keys!["parseApplicationID"] as! String
        let clientKey = keys!["parseClientKey"] as! String
        Parse.setApplicationId(applicationId, clientKey: clientKey)
        
        let application = UIApplication.sharedApplication()
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            let firstAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
            firstAction.identifier = "SHOW_INFO_IDENTIFIER"
            firstAction.title = "Show Info"
            firstAction.activationMode = UIUserNotificationActivationMode.Foreground
            firstAction.destructive = false
            firstAction.authenticationRequired = false
            
            let secondAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
            secondAction.identifier = "LISTEN_NOW_IDENTIFIER"
            secondAction.title = "Listen Now"
            secondAction.activationMode = UIUserNotificationActivationMode.Foreground
            secondAction.destructive = false
            secondAction.authenticationRequired = false
            
            let firstCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
            firstCategory.identifier = "EVENT_CATEGORY"
            
            let defaultActions:NSArray = [firstAction, secondAction]
            let minimalActions:NSArray = [firstAction, secondAction]
            
            firstCategory.setActions(defaultActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Default)
            firstCategory.setActions(minimalActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Minimal)
            
            let categories:NSSet = NSSet(object: firstCategory)
            
            let types:UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: categories as? Set<UIUserNotificationCategory>)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
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