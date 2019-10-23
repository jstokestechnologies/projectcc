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
import SDWebImage
import Stripe
import UIKit


var db = Firestore.firestore()
var userdata = UserData()
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Initialize Facebook SDK
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //Initialize FireBase SDK
        FirebaseApp.configure()
        
        //Initialize Fabric SDK
        Fabric.with([Crashlytics.self])
        
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
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }else {
            return (GIDSignIn.sharedInstance()?.handle(url))!
        }

    }
}

