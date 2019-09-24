//
//  EditProfileVC.swift
//  FireDB
//
//  Created by admin on 12/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage



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
    
    @IBOutlet weak var btnSaveProfile: UIButton!
    
    var delegate : UpdateProfileDelegate?
    
    lazy var storage = Storage.storage()
    let picker = UIImagePickerController()
    var isProfilePicChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showProfileImage()
        self.showProfileData()
        if self.delegate == nil {
            self.btnSaveProfile.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func showProfileImage() {
        if let img = userdata.profile_pic {
            let url = URL.init(fileURLWithPath: img)
            if url.pathExtension != "" {
                let storageRef = storage.reference(withPath: img)
                self.imgProfile.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"), completion: { (downloadedImage, err, cache, ref) in
                    if let error = err {
                        print(error.localizedDescription)
                        self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .refreshCached, context: nil)
                    }})
            }else {
                self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .refreshCached, context: nil)
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
        self.txtPhoneNo.text = userdata.phone_number
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
    
    func saveDataToFireBase(profile_data : NSMutableDictionary) {
        progressView.showActivity()
        db.collection("Users").document(userdata.id).setData(profile_data as! [String : Any], completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
                
                HelperClass.saveDataToDefaults(dataObject: profile_data, key: kUserData)
                progressView.hideActivity()
                if self.delegate != nil {
                    self.navigationController?.popViewController(animated: true)
                    self.delegate?.userUpdatedProfile(success: true)
                }
//                HelperClass.showAlert(msg: "Profile updated successfully", isBack: true, vc: self)
            }
        })
    }
    
    func saveProfileImage() -> String {
        let spaceRef = storage.reference().child("profile/\(userdata.id).jpeg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imgData = (self.imgProfile.image)!.jpegData(compressionQuality: 0.25)
        spaceRef.putData(imgData!, metadata: metadata)
        
        let storageRef = self.storage.reference(withPath: (userdata.profile_pic)!)
        storageRef.downloadURL { (url, err) in
            if url != nil {
                SDImageCache.shared.removeImage(forKey: (url?.absoluteString)!, cacheType: .all, completion: nil)
            }
        }
        
        return spaceRef.fullPath
    }
    
    @IBAction func btnSelectImageAction(_ sender : UIButton) {
        self.view.endEditing(true)
        let alert:UIAlertController=UIAlertController(title: "Select Image", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        alert.addAction(UIAlertAction(title: "Open Camera", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openGallary()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
        })
        picker.delegate = self
        picker.allowsEditing = true
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnSaveAction(_ sender : UIButton) {
        self.view.endEditing(true)
//        if self.validateTextFields() {
//            let alert = UIAlertController.init(title: nil, message: "Do you want to save changes?", preferredStyle: .alert)
//            alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alrt) in
                self.saveProfileData()
//            }))
//            alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alrt) in
//            }))
//            self.present(alert, animated: true, completion: nil)
//        }
    }
    
    func saveProfileData() {
        var imgPath = userdata.profile_pic != nil ? userdata.profile_pic! : ""
        if isProfilePicChanged {
            imgPath = self.saveProfileImage()
        }
        let param = HelperClass.fetchDataFromDefaults(with: kUserData).mutableCopy() as! NSMutableDictionary
        param["city"        ] = self.txtCity.text!
        param["state"       ] = self.txtState.text!
        param["street"      ] = self.txtStreetNo.text!
        param["apartment_no"] = self.txtApatmentNo.text!
        param["zipcode"     ] = self.txtZipCode.text!
        param["phone_number"] = self.txtPhoneNo.text!
        param["mpc"         ] = self.txtMpc.text!
        param["sub_division"] = self.txtSubDivision.text!
        param["name"        ] = self.txtName.text!
        if isProfilePicChanged && imgPath.count > 0 {
            param["profile_pic" ] = imgPath
        }
        
        self.saveDataToFireBase(profile_data: param)
    }
    
    func openCamera()
    {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            picker.sourceType = UIImagePickerController.SourceType.camera
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func openGallary()
    {
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    func validateTextFields() -> Bool {
        if (self.txtName.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter name.", isBack: false, vc: self)
            return false
        }else if (self.txtStreetNo.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter street name.", isBack: false, vc: self)
            return false
        }/*else if (self.txtApatmentNo.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter apartment number.", isBack: false, vc: self)
            return false
        }*/else if (self.txtCity.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter city name.", isBack: false, vc: self)
            return false
        }else if (self.txtState.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter state.", isBack: false, vc: self)
            return false
        }else if (self.txtZipCode.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter zipcode.", isBack: false, vc: self)
            return false
        }else if (self.txtPhoneNo.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter phone number.", isBack: false, vc: self)
            return false
        }else if (self.txtPhoneNo.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 8 {
            HelperClass.showAlert(msg: "Please enter valid phone number.", isBack: false, vc: self)
            return false
        }else if (self.txtMpc.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter MPC.", isBack: false, vc: self)
            return false
        }else if (self.txtSubDivision.text?.trimmingCharacters(in: .whitespaces).count ?? 0) <= 0 {
            HelperClass.showAlert(msg: "Please enter sub division.", isBack: false, vc: self)
            return false
        }
        return true
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

//MARK: -
extension EditProfileVC : UITextFieldDelegate {
    //MARK: TextField Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" || (textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)) == "" {
            
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil && string != "," && string != " " {
            return false
        }
        if textField == txtPhoneNo {
            if (textField.text!.count + string.count) > 10 && string != "" {
                return false
            }
        }else if textField == txtZipCode {
            if (textField.text!.count + string.count) > 6 && string != "" {
                return false
            }
        }else {
            if (textField.text!.count + string.count) > 50 && string != "" {
                return false
            }
        }
        self.btnSaveProfile.isHidden = false
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == self.txtSubDivision {
            textField.resignFirstResponder()
//        }else if let txtField = textField.next?.next as? UITextField {
//            txtField.becomeFirstResponder()
//        }
        return true
    }
}

//MARK: -
extension EditProfileVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.btnSaveProfile.isHidden = false
        if let img = info[.editedImage] as? UIImage {
            self.imgProfile?.image = img
        }else if let img = info[.originalImage] as? UIImage {
            self.imgProfile?.image = img
        }
        isProfilePicChanged = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
