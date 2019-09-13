//
//  EditProfileVC.swift
//  FireDB
//
//  Created by admin on 12/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase

class EditProfileVC: UIViewController {
    
    @IBOutlet weak var imgProfile: UIImageView!
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtStreetNo: UITextField!
    @IBOutlet weak var txtApatmentNo: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var txtState: UITextField!
    @IBOutlet weak var txtZipCode: UITextField!
    @IBOutlet weak var txtPhoneNo: UITextField!
    @IBOutlet weak var txtMpc: UITextField!
    @IBOutlet weak var txtSubDivision: UITextField!
    
    
    lazy var storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.showProfileData()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userdata.profile_pic = "http://graph.facebook.com/10156247148412161/picture?type=large"
        if let img = userdata.profile_pic {
            let url = URL.init(fileURLWithPath: img)
            if url.pathExtension != "" {
                let storageRef = storage.reference(withPath: img)
                self.imgProfile.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
            }else {
                self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .retryFailed, context: nil)
            }
        }
        DispatchQueue.main.async {
            self.imgProfile.layer.cornerRadius = self.imgProfile.frame.height/2
        }
    }
    
    func showProfileData() {
        self.txtName.text = userdata.name
        self.txtStreetNo.text = userdata.street
        self.txtApatmentNo.text = userdata.apartment_no
        self.txtCity.text = userdata.city
        self.txtState.text = userdata.state
        self.txtZipCode.text = userdata.zipcode
        self.txtPhoneNo.text = userdata.mpc
        self.txtMpc.text = userdata.mpc
        self.txtSubDivision.text = userdata.sub_division
        
        // Set city and state name if not set
        if let location = (userdata.location)?["name"] {
            self.setLocation(location)
        }else if let location = (userdata.hometown)?["name"] {
            self.setLocation(location)
        }
        
        // Set address
    }
    
    func setLocation(_ location : String) {
        var strCity = ""
        var strState = ""
        let arrLocation = location.components(separatedBy: ",")
        if arrLocation.count > 0 {
            strCity = arrLocation.first ?? ""
        }
        if arrLocation.count > 1 {
            strState = arrLocation[1]
        }
        if (self.txtCity.text?.count ?? 0) <= 0 {
            self.txtCity.text = strCity
        }
        if (self.txtState.text?.count ?? 0) <= 0 {
            self.txtState.text = strState
        }
    }
    
    func saveDataToFireBase(profile_data : [String : Any]) {
        db.collection("Users").document(userdata.id).setData(profile_data, completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
            }
        })
    }
    
    func saveProfileImage() -> String {
        let spaceRef = storage.reference().child("profile/\(userdata.id).jpeg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imgData = (self.imgProfile.image)!.jpegData(compressionQuality: 0.25)
        spaceRef.putData(imgData!, metadata: metadata)
        
        return spaceRef.fullPath
    }
    
    @IBAction func btnSelectImageAction(_ sender : UIButton) {
        
    }
    
    @IBAction func btnSaveAction(_ sender : UIButton) {
        let imgPath = self.saveProfileImage()
        
        let param = ["city"         : self.txtCity.text!,
                     "state"        : self.txtState.text!,
                     "street"       : self.txtStreetNo.text!,
                     "apartment_no" : self.txtApatmentNo.text!,
                     "zipcode"      : self.txtZipCode.text!,
                     "phone_number" : self.txtPhoneNo.text!,
                     "mpc"          : self.txtMpc.text!,
                     "sub_division" : self.txtSubDivision.text!,
                     "name"         : self.txtName.text!,
                     "profile_pic"  : imgPath]
        
        self.saveDataToFireBase(profile_data: param)
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
