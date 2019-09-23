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
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn



class ViewController: UIViewController {
    
    @IBOutlet weak var btnShowListedItems: UIButton!
    //MARK: - Variables
    let connection = GraphRequestConnection()
    
    enum LoginType {
        case fb
        case google
    }
    var fbUserData = [String : Any]()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
    }
    
    //MARK: - Firebase -> Save Data
    func saveDataToFireBase(loginDict : [String : Any]) {
        db.collection("Users").document("\(loginDict["id"] ?? "N/A")").setData(loginDict, completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
            }
        })
    }
    
    func checkPreviousLogin(key : String, value : String, completion : @escaping (_ loginData : [String : Any]?, _ success : Bool) -> Void) {
        db.collection("Users").whereField(key, isEqualTo: value).getDocuments { (docs, err) in
            if let error = err {
                print(error.localizedDescription)
                completion(nil, false)
            }else if let documents = docs?.documents, documents.count > 0 {
                let doc = documents.first
                var loginDict : [String : Any]? = nil
                if let dict = doc?.data() {
                    loginDict = dict
                }
                completion(loginDict, true)
            }else {
                completion(nil, true)
            }
        }
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
                                                progressView.showActivity()
                                                self.fetchDataFromFacebook(completion: { (fbData) in
                                                    if fbData != nil {
                                                        var username = ""
                                                        var key = "email"
                                                        if let email = fbData!["email"] as? String {
                                                            username = email
                                                        }else if let fb_id = fbData!["id"] as? String {
                                                            username = fb_id
                                                            key = "fb_id"
                                                        }
                                                        self.checkPreviousLogin(key: key, value: username, completion: { (userData, success) in
                                                            if success {
                                                                if let user = userData {
                                                                    self.saveDataAndNavigateToHome(loginDict: user as NSDictionary, saveToFirebase: false)
                                                                }else {
                                                                    self.authenticateFireBase(cred: credential, loginType: .fb)
                                                                }
                                                            }else {
                                                                progressView.hideActivity()
                                                            }
                                                        })
                                                    }else {
                                                        progressView.hideActivity()
                                                    }
                                                })
                                            }
        }
    }
    
    @IBAction func btnGoogleTapped(_ sender: UIButton) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    //MARK: - Login Helper
    func authenticateFireBase(cred : AuthCredential, loginType : LoginType) {
        Auth.auth().signIn(with: cred, completion: { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                progressView.hideActivity()
                return
            }else {
                //User authenticated to Firebase
                if loginType == .fb {
                    self.fbUserData["fb_id"] = self.fbUserData["id"] as? String ?? "Na"
                    self.fbUserData["id"] = Auth.auth().currentUser?.uid ?? ""
                    self.saveDataAndNavigateToHome(loginDict: self.fbUserData as NSDictionary, saveToFirebase: true)
                }else if loginType == .google {
                    let userData = GIDSignIn.sharedInstance()?.currentUser.profile
                    let loginData : NSDictionary = ["name"         : userData?.name ?? "",
                                     "first_name"   : userData?.givenName ?? "",
                                     "last_name"    : userData?.familyName ?? "",
                                     "email"        : userData?.email ?? "",
                                     "id"           : Auth.auth().currentUser?.uid ?? "",
                                     "profile_pic"  : (userData?.imageURL(withDimension: 100))?.absoluteString ?? "",
                                     "google_id"    : GIDSignIn.sharedInstance()?.clientID ?? "Na"]
                    self.saveDataAndNavigateToHome(loginDict: loginData, saveToFirebase: true)
                }
            }
        })
    }
    
    func fetchDataFromFacebook( completion : @escaping (_ loginData : [String : Any]?) -> Void) {
        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, gender, birthday, hometown, location, likes, tagged, address, age_range, can_review_measurement_request, favorite_athletes, favorite_teams, inspirational_people, install_type, is_shared_login, languages, name_format, quotes, short_name, significant_other, security_settings, about, education"]).start(completionHandler: { (connection, result, error) -> Void in
            if (error == nil){
                if let fbDetails = result as? [String : Any] {
                    self.fbUserData = fbDetails
                    completion(fbDetails)
                }else {
                    completion(nil)
                }
            }else {
                print(error?.localizedDescription ?? "Unknown Error.")
                progressView.hideActivity()
                completion(nil)
            }
        })
    }
    
    func saveDataAndNavigateToHome(loginDict : NSDictionary, saveToFirebase : Bool) {
        HelperClass.saveDataToDefaults(dataObject: loginDict, key: kUserData)
        if userdata.profile_pic == nil {
            userdata.profile_pic = "http://graph.facebook.com/\(userdata.id)/picture?type=large"
            loginDict.setValue(userdata.profile_pic!, forKey: "profile_pic")
        }
        if saveToFirebase {
            self.saveDataToFireBase(loginDict: loginDict as! [String : Any])
        }
        UIApplication.shared.keyWindow?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "TabVc")
        progressView.hideActivity()
    }
}


extension ViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        progressView.showActivity()
        self.checkPreviousLogin(key: "email", value: user.profile.email ?? "na") { (userDict, success) in
            if success {
                if let user = userDict {
                    self.saveDataAndNavigateToHome(loginDict: user as NSDictionary, saveToFirebase: false)
                }else {
                    self.authenticateFireBase(cred: credential, loginType: .google)
                }
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print(error.localizedDescription)
    }
}
