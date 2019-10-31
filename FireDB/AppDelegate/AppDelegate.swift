//
//  AppDelegate.swift
//  FireDB
//
//  Created by admin on 30/07/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Crashlytics
import Fabric
import FBSDKCoreKit
import Firebase
import FirebaseFirestore
import GoogleSignIn
import IQKeyboardManagerSwift
import FirebaseMessaging
import SDWebImage
import Stripe
import UIKit
import UserNotifications
import UserNotificationsUI


var db = Firestore.firestore()
var userdata = UserData()
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register remote notifications
        self.applicationRegisterForNotifications()
        
        //Initialize Facebook SDK
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //Initialize FireBase SDK
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        
        //Initialize Fabric SDK
//        Fabric.with([Crashlytics.self])
        
        //Initialize Google Signin SDK
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        if UserDefaults.standard.bool(forKey: kIsLoggedIn) {
            let userDict = HelperClass.fetchDataFromDefaults(with: kUserData)
            HelperClass.setUserDataModel(userDict: userDict)
            
            self.window?.rootViewController = mainStoryBoard.instantiateViewController(withIdentifier: "TabVc")
        }
        
        //Configure Stripe
        Stripe.setDefaultPublishableKey("pk_test_4dJsL1teFhhtbNF8QaoyGlCp00VXw1CfBH")
        STPPaymentConfiguration.shared().appleMerchantIdentifier = "pk_test_xOX9CL9odOMP0r4AUx01QSxC00yuuu3j2H"
        
//        SDImageCache.shared.clearMemory()
//        SDImageCache.shared.clearDisk()
        IQKeyboardManager.shared.enable = true
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
        application.applicationIconBadgeNumber = 0
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationRegisterForNotifications() {
        
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("\n\n\n\nAPN Device Token : \(deviceToken.hexString)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }else {
            return (GIDSignIn.sharedInstance()?.handle(url))!
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("FCM Device token : \(fcmToken)")
        if UserDefaults.standard.bool(forKey: kIsLoggedIn) && userdata.id != "" {
            self.saveFcmToken(token: fcmToken)
        }else {
            UserDefaults.standard.set(fcmToken, forKey: kDeviceToken)
            UserDefaults.standard.synchronize()
        }
    }
    
    func saveFcmToken(token : String) {
        db.collection(kUsersCollection).document(userdata.id).setData(["fcm_token" : token], merge: true)
    }
    
    
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

