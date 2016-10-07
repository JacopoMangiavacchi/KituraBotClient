//
//  AppDelegate.swift
//  KituraBot
//
//  Created by Jacopo Mangiavacchi on 10/3/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import UIKit
import UserNotifications
import Intents
import KituraBotFramework

import BMSCore
import BMSPush


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        //request authorization for notification
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorization.
            if (granted)
            {
                application.registerForRemoteNotifications()
            }
            else{
                //Do stuff if unsuccessful...
            }
        }
        
        center.delegate = self
        
        
        //Register to Bluemix notification server
        BMSClient.sharedInstance.initialize(bluemixRegion: Configuration.bluemixRegion)
        BMSPushClient.sharedInstance.initializeWithAppGUID(appGUID: Configuration.appGUID, clientSecret: Configuration.clientSecret)


        //request authorization for siri
        INPreferences.requestSiriAuthorization { status in
            // Handle authorization if necessary
            print("Siri status: \(status)")
        }
        
        INVocabulary.shared().setVocabularyStrings([Configuration.appName], of: .contactName)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // implement to handle user activity created by Siri or by our SiriExtension
        
        if let userInfo = userActivity.userInfo {
            for (key, value) in userInfo {
                
                print(key)
                print(value)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        
        print("Token = \(token)")
        
        
        BMSPushClient.sharedInstance.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
            if error.isEmpty {
                print( "Response during device registration : \(response)")
                print( "status code during device registration : \(statusCode)")
                
                let devId  = BMSClient.sharedInstance.authorizationManager.deviceIdentity.ID

                print("DevideId = \(devId)")
                
                KituraBotShared.storeDeviceId(devId)
                
            } else{
                print( "Error during device registration \(error) ")
                print( "Error during device registration \n  - status code: \(statusCode) \n Error :\(error) \n")
            }
        }
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}


// MARK UNNotificationCenter Delegate Methods
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        /**
         If your app is in the foreground when a notification arrives, the notification center calls this method to deliver the notification directly to your app. If you implement this method, you can take whatever actions are necessary to process the notification and update your app. When you finish, execute the completionHandler block and specify how you want the system to alert the user, if at all.
         
         If your delegate does not implement this method, the system silences alerts as if you had passed the UNNotificationPresentationOptionNone option to the completionHandler block. If you do not provide a delegate at all for the UNUserNotificationCenter object, the system uses the notification’s original options to alert the user.
         
         see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter
         
         **/
        
        print("APPDELEGATE: willPresentNotification \(notification.request.content.userInfo)")
        
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        /**
         Use this method to perform the tasks associated with your app’s custom actions. When the user responds to a notification, the system calls this method with the results. You use this method to perform the task associated with that action, if at all. At the end of your implementation, you must call the completionHandler block to let the system know that you are done processing the notification.
         
         You specify your app’s notification types and custom actions using UNNotificationCategory and UNNotificationAction objects. You create these objects at initialization time and register them with the user notification center. Even if you register custom actions, the action in the response parameter might indicate that the user dismissed the notification without performing any of your actions.
         
         If you do not implement this method, your app never responds to custom actions.
         
         see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter
         
         **/
        
        print("APPDELEGATE: didReceiveResponseWithCompletionHandler \(response.notification.request.content.userInfo)")
        
        
        completionHandler()
        
    }
}
