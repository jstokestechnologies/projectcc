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
    
    @IBOutlet weak var txtData: UITextView!
    
    var loginDict = Dictionary<String,Any>()
    let arrTitle = ["First Name", "Last Name", "Email", "Gender", "Birthday", "Hometown", "Current Location", "Relationship Status"]
    let arrKeys = ["first_name", "last_name", "email", "gender", "birthday", "hometown.name", "location.name"]
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.saveData()
        // Do any additional setup after loading the view.
        self.txtData.text = "\(loginDict)"
        DispatchQueue.main.async {
            self.txtData.scrollRectToVisible(CGRect.init(origin: CGPoint.zero, size: CGSize(width: 50, height: 10)), animated: false)
        }
    }
    
    func saveData() {
//        var ref: DocumentReference? = nil
//        ref = db.collection("users").addDocument(data: self.loginDict) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID:\n\n\n\n\n \(ref!.documentID)")
//            }
//        }
        
         db.collection("Users").document("\(loginDict["id"] ?? "N/A")").setData(self.loginDict, completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
            }
        })
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
        return self.arrKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = arrTitle[indexPath.row]
        cell.detailTextLabel?.text = "\(loginDict[arrKeys[indexPath.row]] ?? "N/A")"
        cell.detailTextLabel?.text = "\((loginDict as NSDictionary).value(forKeyPath: arrKeys[indexPath.row]) ?? "N/A")"
        return cell
    }
}

