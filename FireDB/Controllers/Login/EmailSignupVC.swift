//
//  EmailSignupVC.swift
//  FireDB
//
//  Created by admin on 19/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase

class EmailSignupVC: UIViewController {
    
    let handler = Auth.auth().addStateDidChangeListener { (auth, user) in
        // ...
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handler)
    }
    
    @IBAction func btnLoginAction(_ sender : UIButton) {
        Auth.auth().signIn(withEmail: "test@mailinator.com", password: "123456") { [weak self] user, error in
            guard let strongSelf = self else { return }
            if let err = error {
                print(err.localizedDescription)
            }else {
                print(user?.credential)
            }
        }
    }
    
    @IBAction func btnSignupAction(_ sender : UIButton) {
        Auth.auth().createUser(withEmail: "harsh@particle41.com", password: "123456") { authResult, error in
            if let err = error {
                print(err.localizedDescription)
            }else {
                print(authResult?.credential)
            }
        }
    }
    
    @IBAction func btnResetPasswordAction(_ sender : UIButton) {
        
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://www.example.com")
        // The sign-in operation has to always be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendPasswordReset(withEmail: "test@mailinator.com", actionCodeSettings: actionCodeSettings) { (err) in
            if let error = err {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func btnVerifyEmailAction(_ sender : UIButton) {
        Auth.auth().currentUser?.sendEmailVerification { (error) in
            if let err = error {
                print(err.localizedDescription)
            }
        }
    }
    
    @IBAction func btnSignoutAction(_ sender : UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
