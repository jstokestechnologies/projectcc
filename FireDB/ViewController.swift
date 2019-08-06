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



class ViewController: UIViewController {
    
    let connection = GraphRequestConnection()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnFacebookTapped(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(permissions: [.publicProfile, .email, .userBirthday ,.userHometown, .userLocation, .userGender, .userLikes, .userPosts, .userTaggedPlaces], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in! \(grantedPermissions.description), Token : \(accessToken.tokenString), DeclinePermition Details : \(declinedPermissions.description)")
                GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, gender, birthday, hometown, location, likes, tagged"]).start(completionHandler: { (connection, result, error) -> Void in
                    if (error == nil){
                        let fbDetails = result as! NSDictionary
                        print(fbDetails)
                        
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ShowLoginDataVC") as! ShowLoginDataVC
                        vc.loginDict = fbDetails as! [String : Any]
                        self.navigationController?.show(vc, sender: self)
                        
                    }else {
                        print(error?.localizedDescription ?? "Unknown Error.")
                    }
                })
            }
        }
    }
}



