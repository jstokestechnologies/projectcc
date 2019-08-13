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



class ViewController: UIViewController {
    
    let connection = GraphRequestConnection()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnFacebookTapped(_ sender: Any) {
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
                
                //get facebook access token
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                // Signin with facebook into Firebase
                Auth.auth().signIn(with: credential, completion: { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }else {
                        //User authenticated to Firebase
                        print("Logged in! \(grantedPermissions.description), Token : \(accessToken.tokenString), DeclinePermition Details : \(declinedPermissions.description)")
                        //Getting user details from Facebook from Facebook's Graph API
                        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, gender, birthday, hometown, location, likes, tagged, address, age_range, can_review_measurement_request, favorite_athletes, favorite_teams, inspirational_people, install_type, is_shared_login, languages, name_format, quotes, short_name, significant_other, security_settings, about, education"]).start(completionHandler: { (connection, result, error) -> Void in
                            if (error == nil){
                                let fbDetails = result as! NSDictionary
                                print(fbDetails)
                                HelperClass.saveDataToDefaults(dataObject: fbDetails, key: kUserData)
                                
                                do {
                                    let jsonData  = try? JSONSerialization.data(withJSONObject: fbDetails, options:.prettyPrinted)
                                    let jsonDecoder = JSONDecoder()
//                                    var userdata = UserData.sharedInstance
                                    userdata = try jsonDecoder.decode(UserData.self, from: jsonData!)
                                    print(userdata.id)
                                }
                                catch {
                                    print(error.localizedDescription)
                                }

                                
                                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ShowLoginDataVC") as! ShowLoginDataVC
                                vc.loginDict = fbDetails as! [String : Any]
                                let btn = UIButton.init()
                                btn.setTitle("Logout", for: .normal)
                                vc.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: btn)
                                UIApplication.shared.keyWindow?.rootViewController = UINavigationController.init(rootViewController: vc)
                            }else {
                                print(error?.localizedDescription ?? "Unknown Error.")
                            }
                        })
                    }
                })
                
            }
        }
    }
}


