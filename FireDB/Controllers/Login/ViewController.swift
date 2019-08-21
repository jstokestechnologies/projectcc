//
//  ViewController.swift
//  FireDB
//
//  Created by admin on 30/07/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseFirestore



class ViewController: UIViewController {
    @IBOutlet weak var btnShowListedItems: UIButton!
    //MARK: - Variables
    let connection = GraphRequestConnection()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    //MARK: - Firebase -> Save Data
    func saveData(loginDict : [String : Any]) {
        //        var ref: DocumentReference? = nil
        //        ref = db.collection("users").addDocument(data: self.loginDict) { err in
        //            if let err = err {
        //                print("Error adding document: \(err)")
        //            } else {
        //                print("Document added with ID:\n\n\n\n\n \(ref!.documentID)")
        //            }
        //        }
        
        db.collection("Users").document("\(loginDict["id"] ?? "N/A")").setData(loginDict, completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
            }
        })
    }
    
    //MARK: - IBAction
    @IBAction func btnFacebookTapped(_ sender: UIButton) {
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(permissions: [.publicProfile,
                                         .email,
                                         .userBirthday,
                                         .userHometown,
                                         .userLocation,
                                         .userGender,
                                         .userLikes,
                                         .userPosts,
                                         .userFriends,
                                         .userVideos,
                                         .userTaggedPlaces], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in! \(grantedPermissions.description), Token : \(accessToken.tokenString), DeclinePermition Details : \(declinedPermissions.description)")
                //get facebook access token
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                // Signin with facebook into Firebase
                self.authenticateFireBase(cred: credential)
//                HelperClass.showProgressView()
                progressView.showActivity()
            }
        }
    }
    
    //MARK: - Login Helper
    func authenticateFireBase(cred : AuthCredential) {
        Auth.auth().signIn(with: cred, completion: { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
//                HelperClass.hideProgressView()
                progressView.hideActivity()
                return
            }else {
                //User authenticated to Firebase
                self.fetchDataFromFacebook()
            }
        })
    }
    
    func fetchDataFromFacebook() {
        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, gender, birthday, hometown, location, likes, tagged, address, age_range, can_review_measurement_request, favorite_athletes, favorite_teams, inspirational_people, install_type, is_shared_login, languages, name_format, quotes, short_name, significant_other, security_settings, about, education"]).start(completionHandler: { (connection, result, error) -> Void in
            if (error == nil){
                let fbDetails = result as! NSDictionary
                print(fbDetails)
                self.saveUserData(userDict: fbDetails)
                self.initUserModel(userDict: fbDetails)
                UIApplication.shared.keyWindow?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainNavVC")
                progressView.hideActivity()
            }else {
                print(error?.localizedDescription ?? "Unknown Error.")
                progressView.hideActivity()
            }
        })
    }
    
    func saveUserData(userDict : NSDictionary) {
        HelperClass.saveDataToDefaults(dataObject: userDict, key: kUserData)
        self.saveData(loginDict: userDict as! [String : Any])
    }
    
    func initUserModel(userDict : NSDictionary) {
        do {
            let jsonData  = try? JSONSerialization.data(withJSONObject: userDict, options:.prettyPrinted)
            let jsonDecoder = JSONDecoder()
            //                                    var userdata = UserData.sharedInstance
            userdata = try jsonDecoder.decode(UserData.self, from: jsonData!)
            print(userdata.id)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}


