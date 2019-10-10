//
//  ShowLoginDataVC.swift
//  FireDB
//
//  Created by admin on 30/07/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage

class ShowLoginDataVC: UIViewController {
    
    @IBOutlet weak var btnShowListedItems: UIButton!
    @IBOutlet weak var btnShowSavedItems: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    
    var loginDict = Dictionary<String,Any>()
    let arrTitle = ["Edit Profile", "Listed Items", "Archived Items", "Logout"]
//    let arrKeys = ["first_name", "last_name", "email", "gender", "birthday", "hometown.name", "location.name"]
//    let db = Firestore.firestore()
    
    lazy var storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "More"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showUserData()
    }
    
    func showUserData() {
        self.lblName.text = userdata.name
        self.lblEmail.text = userdata.email
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.lblVersion.text = appVersion
        }else {
            self.lblVersion.text = ""
        }
        if let img = userdata.profile_pic {
            let url = URL.init(string: img)
            if url != nil && url?.pathExtension != "" {
                let placeholderImg = self.imgProfile.image
                let storageRef = storage.reference(withPath: img)
                self.imgProfile.sd_setImage(with: storageRef, maxImageSize: 200000, placeholderImage: placeholderImg ?? UIImage.init(named: "no-image"), options: .fromLoaderOnly, completion: { (downloadedImage, err, cache, ref) in
                    if let error = err {
                        print(error.localizedDescription)
                        self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .retryFailed, context: nil)
                    }})
            }else {
                self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .retryFailed, context: nil)
            }
        }
    }
    
    func logoutUser() {
        self.view.endEditing(true)
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to logout?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            UserDefaults.standard.removeObject(forKey: kUserData)
            UserDefaults.standard.set(false, forKey: kIsLoggedIn)
            UserDefaults.standard.synchronize()
            userdata = UserData()
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            UIApplication.shared.keyWindow?.rootViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LoginNavVC")
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showMyItemsList(isSavedItem : Bool) {
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
        vc.listType = isSavedItem ? .savedItems : .listedItems
        self.navigationController?.show(vc, sender: self)
    }
    
    func showDeletedItemsList() {
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "SoldItemsListVC") as! SoldItemsListVC
        self.navigationController?.show(vc, sender: self)
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

extension ShowLoginDataVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrTitle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = arrTitle[indexPath.row]
        if indexPath.row == 4 {
            cell.accessoryType = .none
        }else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = mainStoryBoard.instantiateViewController(withIdentifier: "EditProfileVC")
            self.navigationController?.show(vc, sender: self)
        case 1:
            self.showMyItemsList(isSavedItem: false)
        case 2:
            self.showDeletedItemsList()
        case 3:
            self.logoutUser()
        default :
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}

