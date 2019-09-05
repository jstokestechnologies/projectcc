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

class ShowLoginDataVC: UIViewController {
    
    @IBOutlet weak var btnShowListedItems: UIButton!
    @IBOutlet weak var btnShowSavedItems: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    
    var loginDict = Dictionary<String,Any>()
    let arrTitle = ["Edit Profile", "Drafted Items", "Listed Items", "Archived Items", "Logout"]
//    let arrKeys = ["first_name", "last_name", "email", "gender", "birthday", "hometown.name", "location.name"]
//    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "More"
        self.showUserData()
    }
    
    func showUserData() {
        self.lblName.text = userdata.name
        self.lblEmail.text = userdata.email
    }
    
    func logoutUser() {
        self.view.endEditing(true)
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to logout?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            UserDefaults.standard.removeObject(forKey: kUserData)
            UserDefaults.standard.set(false, forKey: kIsLoggedIn)
            UserDefaults.standard.synchronize()
            userdata = UserData()
            UIApplication.shared.keyWindow?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginNavVC")
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showMyItemsList(isSavedItem : Bool) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
        vc.listType = isSavedItem ? .savedItems : .listedItems
        self.navigationController?.show(vc, sender: self)
    }
    
    func showDeletedItemsList() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SoldItemsListVC") as! SoldItemsListVC
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
            return
        case 1:
            self.showMyItemsList(isSavedItem: true)
        case 2:
            self.showMyItemsList(isSavedItem: false)
        case 3:
            self.showDeletedItemsList()
        case 4:
            self.logoutUser()
        default :
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}

