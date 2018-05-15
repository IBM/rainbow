//
//  AppDelegate.swift
//  rainbow
//
//  Created by David Okun IBM on 4/30/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import CoreData
import BMSCore
import BMSPush
import UserNotifications
import UserNotificationsUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BMSPushObserver {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.statusBarStyle = .lightContent
        UINavigationBar.appearance().barTintColor = UIColor.RainbowColors.blue
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.RainbowFonts.bold(size: 20)]
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = UIColor.RainbowColors.pale
        UITabBar.appearance().tintColor = UIColor.RainbowColors.copy
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
        
        /// MARK: push notificaiton settings
        BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)
        // MARK: remove the hardcoding in future
        BMSPushClient.sharedInstance.initializeWithAppGUID(appGUID: "c8a1c28e-3934-4e03-b8e2-e305ada1bb85", clientSecret: "cead9064-e0a6-4a0e-86c0-b6bbf060d871")
        BMSPushClient.sharedInstance.delegate = self
        return true
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
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "rainbow")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // very weak error handling, but not sure what else we can do for something this simple
                print("Error while loading persistent store container: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // very weak error handling, but not sure what else we can do for something this simple
                let nserror = error as NSError
                print("Error while saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - push notification
    func onChangePermission(status: Bool) {
        print("Push Notification is enabled:  \(status)" as NSString)
    }
    
    func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
        
        let push =  BMSPushClient.sharedInstance
        push.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
            if error.isEmpty {
                print( "Response during device registration : \(String(describing: response))")
                print( "status code during device registration : \(String(describing: statusCode))")                
            } else {
                print( "Error during device registration \(error) ")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let message: String = "Error registering for push notifications: \(error.localizedDescription)"
        self.showAlert(title: "Registering for notifications", message: message)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let apsDict = (userInfo as NSDictionary).value(forKey: "aps") as? NSDictionary else {
            print("Error while casting aps")
            return
        }
        
        guard let alertDict = apsDict.value(forKey: "alert") as? NSDictionary else {
            print("Error while casting alert")
            return
        }
        
        guard let bodyString = alertDict.value(forKey: "body") as? String else {
            print("Error while casting body")
            return
        }
        print(bodyString)
    }
    
    func showAlert (title: String, message: String) {
        // create the alert
        let alert = UIAlertController.init(title: title as String, message: message as String, preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.window!.rootViewController!.present(alert, animated: true, completion: nil)
    }
    
    func convertStringToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            
            guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                return [:]
            }
            return result
        }
        return [:]
    }
}
