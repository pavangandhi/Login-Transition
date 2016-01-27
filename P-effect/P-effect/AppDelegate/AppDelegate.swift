      //
//  AppDelegate.swift
//  P-effect
//
//  Created by Jack Lapin on 14.01.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
   
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        User.registerSubclass()
        Parse.enableLocalDatastore()
        Parse.setApplicationId(Constants.ParseApplicationId.AppID, clientKey: Constants.ParseApplicationId.ClientKey)
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        let buttonTitlePosition = Constants.BackButtonTitle.HideTitlePosition
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(buttonTitlePosition, forBarMetrics: .Default)

        Router.sharedRouter().onStart(true)
        
        Fabric.with([Crashlytics.self])
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert,.Badge,.Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        if application.applicationState != UIApplicationState.Background {
            let oldPushHandlerOnly = !self.respondsToSelector(Selector("application:didReceiveRemoteNotification:fetchCompletionHandler:"))
            let noPushPayload: AnyObject? = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey]
            if oldPushHandlerOnly || noPushPayload != nil {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        
        
        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.channels = ["global"]
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if application.applicationState == .Inactive  {
            // The application was just brought from the background to the foreground,
            // so we consider the app as having been "opened by a push notification."
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
        
        PFPush.handlePush(userInfo)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        if application.applicationState == .Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }

        
        if let photoId: String = userInfo["p"] as? String {
            let targetPhoto = PFObject(withoutDataWithClassName: "Photo", objectId: photoId)
            targetPhoto.fetchIfNeededInBackgroundWithBlock { (object: PFObject?, error: NSError?) -> Void in
                // Show profile view controller
                if error != nil {
                    completionHandler(UIBackgroundFetchResult.Failed)
                } else if PFUser.currentUser() != nil {
                    let viewController = ProfileViewController()
          //          self.navigationController.pushViewController(viewController, animated: true)
                    completionHandler(UIBackgroundFetchResult.NewData)
                } else {
                    completionHandler(UIBackgroundFetchResult.NoData)
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.NoData)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
        let currentInstallation = PFInstallation.currentInstallation()
        if(currentInstallation.badge != 0){
            currentInstallation.badge = 0
        }
    }
    
}