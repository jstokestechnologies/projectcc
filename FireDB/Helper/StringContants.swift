//
//  StringContants.swift
//  FireDB
//
//  Created by admin on 12/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit

let kUserData                   = "user_login_data"
let kUserId                     = "user_id"
let kIsLoggedIn                 = "is_logged_in"
let kDeviceToken                = "device_token"

let secondStoryBoard            = UIStoryboard.init(name: "Second", bundle: Bundle.main)
let mainStoryBoard              = UIStoryboard.init(name: "Main", bundle: Bundle.main)

//Firebase Collections
let kUsersCollection            = "Users"
let kListedItems                = "listed_items"
let kSavedItems                 = "saved_items"
let kCellItemImage              = "CellImg"



// Notification Name
let kNotification_Category      = "Selected Category"
let kNotification_Image         = "Selected Image"
let kNotification_PaySuccess    = "Payment Success"

// Stripe Keys
let kStripePublicKey            = "pk_test_4dJsL1teFhhtbNF8QaoyGlCp00VXw1CfBH"
let kFcmServerKey               = "AAAAwL3bgj8:APA91bGWRb39elxwZUM1Tewz3KwPVWtcj8zUcC9tTpehiu1Yz_bfptQ-821222jz0dzGn5qVfMPhtcMkttwXeaw74Y-JdFJKK1aTFXhPKLxZE1chLrXHOXRqWBCXlKGxfKCEYmfM6CG2"

// URLs

let kBaseURL                    = "https://us-central1-projectcc-a98a4.cloudfunctions.net/"

let URLEphemeralKeys            = "createEphemeralKeys"
let URLPaymentIntent            = "createPaymentIntent"
let URLCapturePayment           = "capturePaymentIntent"
let URLSendNotification         = "sendNotification"







let kArrConditions = [["title":"New",
                       "description":"New with tags (NWT). Unopened packaging. Unused."],
                      ["title":"Like New",
                       "description":"NNew without tags (NWOT). No signs of usage. Looks Unused."],
                      ["title":"Good",
                       "description":"Gently used having few minor scratches. Functioning properly."]]
