//
//  AddSellItemVC.swift
//  FireDB
//
//  Created by admin on 07/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class AddSellItemVC: UITableViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var collectionCondition: UICollectionView!
    @IBOutlet weak var collectionImages: UICollectionView!
    
    @IBOutlet weak var btnSaveDraft: UIButton!
    @IBOutlet weak var btnFreeShipYes: UIButton!
    @IBOutlet weak var btnFreeShipNo: UIButton!
    
    @IBOutlet weak var txtItemName: UITextField!
    @IBOutlet weak var txtItemDescription: UITextView!
//    @IBOutlet weak var txtZipCode: UITextField!
    @IBOutlet weak var txtItemPrice: UITextField!
    
    @IBOutlet weak var lblItemDescriptionRange: UILabel!
    @IBOutlet weak var lblItemNameRange: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblItemColor: UILabel!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var lblBrand: UILabel!
    
    
    //MARK: - Properties
    let picker = UIImagePickerController()
    let arrConditions = [["title":"New","description":"New with tags (NWT). Unopened packaging. Unused."],
                         ["title":"Like New","description":"NNew without tags (NWOT). No signs of usage. Looks Unused."],
                         ["title":"Good","description":"Gently used having few minor scratches. Functioning properly."]]
    let maxImages = 8
    var arrItemImages = Array<UIImage>()
    var itemCondition = 0
    var categories = String()
    var subCategories = [String]()
    
    lazy var storage = Storage.storage()
    
    //MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareViews()
        // Do any additional setup after loading the view.
    }
    
    func prepareViews() {
        self.btnSaveDraft.layer.borderColor = UIColor(red:0.25, green:0.35, blue:0.82, alpha:1.0).cgColor
        self.lblBrand.text = " "
        self.lblCategory.text = " "
    }
    
    //MARK: - IBActions
    
    @IBAction func btnListAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
            self.showSaveAlert(sender: sender, msg: "Are you sure you want to list this item for sale?")
        }
    }
    
    @IBAction func btnSaveDraftAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
           self.showSaveAlert(sender: sender, msg: "Are you sure you want to save this item in draft?")
        }
        
    }
    
    @IBAction func btnRemoveImageAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.arrItemImages.remove(at: 0)
        self.collectionImages.reloadData()
    }
    
    @IBAction func btnFreeShippingAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.btnFreeShipYes.setImage(UIImage.init(named: sender == btnFreeShipYes ? "checked" : "uncheck"), for: .normal)
        self.btnFreeShipNo.setImage(UIImage.init(named: sender == btnFreeShipNo ? "checked" : "uncheck"), for: .normal)
        self.btnFreeShipYes.isSelected = sender == btnFreeShipYes
        self.btnFreeShipNo.isSelected = sender == btnFreeShipNo
    }
    
    @IBAction func btnCloseAction(_ sender: UIButton) {
        self.view.endEditing(true)
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to close this window?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Other
    func showSaveAlert(sender : UIButton, msg : String) {
        let alert = UIAlertController.init(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            if sender == self.btnSaveDraft {
                self.saveData(type: "saved_items")
            }else {
                self.saveData(type: "listed_items")
            }
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveData(type : String) {
        progressView.showActivity()
        self.saveItemDetails(type: type, itemData: self.getItemDetails()) { (err, success) in
            if success {
                self.showAlert(msg: "Item details saved successfully", isBack: true)
            }else {
                
            }
            progressView.hideActivity()
        }
    }
    
    func validateTextFields() -> Bool {
        if self.arrItemImages.count <= 0 {
            self.showAlert(msg: "Please add atleast 1 item image.", isBack: false)
            return false
        }else if self.txtItemName.text == "" || (self.txtItemName.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0) <= 0 {
            self.showAlert(msg: "Please enter item name.", isBack: false)
            return false
        }else if self.txtItemDescription.text == "" || self.txtItemDescription.text.trimmingCharacters(in: .whitespacesAndNewlines).count <= 0 {
            self.showAlert(msg: "Please enter item description.", isBack: false)
            return false
        }else if self.lblCategory.text!.count < 2 {
            self.showAlert(msg: "Please select item category.", isBack: false)
            return false
        }else if self.lblBrand.text!.count < 2 {
            self.showAlert(msg: "Please select brand.", isBack: false)
            return false
        }/*else if self.txtZipCode.text!.count < 5 {
            self.showAlert(msg: "Please enter delivery zipcode", isBack: false)
            return false
        }*/else if self.txtItemPrice.text!.count <= 0 {
            self.showAlert(msg: "Please enter item price.", isBack: false)
            return false
        }
        return true
    }
    
    func getItemDetails() -> Dictionary<String,Any> {
        let timestamp =  Int64(Date().timeIntervalSince1970 * 1000)
        let imgPath = self.saveItemImages(timestamp)
        let itemDetails : [String : Any] = ["item_name"     : (self.txtItemName.text)!,
                                            "description"   : (self.txtItemDescription.text)!,
                                            "category"      : self.categories,
                                            "sub_category"  : self.subCategories,
                                            "brand"         : (self.lblBrand.text)!,
                                            "condition"     : "\(self.arrConditions[self.itemCondition]["title"] ?? "")",
                                            "color"         : (self.lblItemColor.text)!,
//                                            "zipcode"       : (self.txtZipCode.text)!,
//                                            "free_ship"     : self.btnFreeShipYes.isSelected,
                                            "price"         : (self.txtItemPrice.text)!,
                                            "user_id"       : userdata.id,
                                            "item_images"   : imgPath,
                                            "images_added"  : self.arrItemImages.count,
                                            "created"       : timestamp,
                                            "updated"       : timestamp,
                                            "seller_name"   : userdata.name,
                                            "watchers"      : "",
                                            "used_category" : "",
                                            "home_address"  : "",
                                            "mpcName"       : "",
                                            "subdivision"   : "",
                                            "buyerRating"   : "0",
                                            "sellerRating"  : "0",
                                            "bankAccountUpdated" : "0"]
        return itemDetails
    }
    
    func saveItemDetails(type : String, itemData : Dictionary<String,Any>, completionHandler:@escaping (Error?, Bool) -> ()) {
        var ref: DocumentReference? = nil
        ref = db.collection(type).addDocument(data: itemData) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completionHandler(err, false)
            }else {
                print("Document added with ID:\n\n\n\n\n \(ref!.documentID)")
                completionHandler(err, true)
            }
        }
    }
    
    func showAlert(msg : String, isBack : Bool){
        let alert = UIAlertController.init(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (alrt) in
            if isBack {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func saveItemImages(_ timestamp : Int64) -> [String] {
        var imgPaths = [String]()
        
        for i in 0..<self.arrItemImages.count {
            let img = self.arrItemImages[i]
            let spaceRef = storage.reference().child("images/\(userdata.id)-\((Int(Date().timeIntervalSince1970 * 1000)))-\(i+1).jpeg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imgData = img.jpegData(compressionQuality: 0.25)
            spaceRef.putData(imgData!, metadata: metadata)
            
            imgPaths.append(spaceRef.fullPath)
        }
        
        return imgPaths
    }
    
    
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSelectCategory" {
            let vc = segue.destination as! SelectCategoryVC
            vc.previousCategory = self.categories
            vc.arrPreviousSubCat = self.subCategories
            vc.delegate = self
        }else if segue.identifier == "segueSelectBrand" {
            let vc = segue.destination as! SelectBrandVC
            vc.delegate = self
        }
    }
}

//MARK: - TableView Delegate Methods
extension AddSellItemVC {
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let lbl = UILabel.init(frame: CGRect.init(x: 0.0, y: 0.0, width: 100.0, height: 22.0))
        lbl.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.0)
        lbl.text = section == 0 ? "    * REQUIRED" : " "
        lbl.textColor = UIColor(red:0.72, green:0.00, blue:0.02, alpha:1.0)
        lbl.font = UIFont.systemFont(ofSize: 15)
        
        return lbl
    }
}

//MARK: - CollectionView Delegate
extension AddSellItemVC : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionCondition {
            return self.arrConditions.count
        }
        var count = self.arrItemImages.count + 1
        count = count > maxImages ? maxImages : count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = collectionView == self.collectionCondition ? "CellCondition" : (indexPath.row == self.arrItemImages.count ? "CellAdd" : "CellImage")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        let borderColor = (collectionView == self.collectionCondition) ? (self.itemCondition == indexPath.row ? UIColor.blue.cgColor : UIColor.lightGray.cgColor) : (UIColor.init(patternImage: UIImage.init(named: "border_dot.png")!)).cgColor
        cell.layer.borderColor = borderColor
        
        if collectionView == self.collectionCondition {
            (cell.viewWithTag(1) as! UILabel).text = "\(self.arrConditions[indexPath.row]["title"] ?? "New")"
            (cell.viewWithTag(2) as! UILabel).text = "\(self.arrConditions[indexPath.row]["description"] ?? "New")"
            return cell
        }
        
        if indexPath.row < self.arrItemImages.count {
            (cell.viewWithTag(11) as! UIImageView).image = self.arrItemImages[indexPath.row]
//            (cell.contentView.viewWithTag(101) as! UIButton).tag = indexPath.row
            (cell.contentView.viewWithTag(101) as! UIButton).addTarget(self, action: #selector(self.btnRemoveImageAction(_:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionCondition {
            self.itemCondition = indexPath.row
            self.collectionCondition.reloadData()
        }else {
            if self.arrItemImages.count == indexPath.row && self.arrItemImages.count < 8 {
                self.pickImage()
            }
        }
    }
}

//MARK: - Pick Images
extension AddSellItemVC : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.editedImage] as? UIImage {
            self.arrItemImages.append(img)
        }else if let img = info[.originalImage] as? UIImage {
            self.arrItemImages.append(img)
        }
        self.collectionImages.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }
    
    func pickImage() {
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
}

//MARK: -
extension AddSellItemVC : UITextFieldDelegate, UITextViewDelegate {
    //MARK: TextField Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "* What are you selling?" {
            textField.text = ""
            textField.textColor = .darkGray
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "* What are you selling?" || textField.text == "" || (textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)) == "" {
            
            let partOne = NSMutableAttributedString(string: "*", attributes: [NSAttributedString.Key.foregroundColor : UIColor(red:0.72, green:0.00, blue:0.02, alpha:1.0), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)])
            let partTwo = NSMutableAttributedString(string: " What are you selling?", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)])
            
            partOne.append(partTwo)
            
            textField.attributedText = partOne
            self.lblItemNameRange.text = "0/40"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.txtItemName {
            if textField.text!.count >= 40 && string != "" {
                return false
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                self.lblItemNameRange.text = "\(textField.text!.count)/40"
            })
        }/*else if textField == self.txtZipCode {
            if textField.text!.count >= 6 && string != "" {
                return false
            }else if string.rangeOfCharacter(from: .alphanumerics) == nil && string != "" {
                return false
            }
        }*/else if textField == self.txtItemPrice {
            if textField.text!.count >= 10 && string != "" {
                return false
            }else if string.rangeOfCharacter(from: .alphanumerics) == nil && string != "." && string != "" {
                return false
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                self.lblPrice.text = "$\(textField.text!)"
            })
        }
        
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: TextView Delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "* Describe your item (5+ Words)" {
            textView.text = ""
            textView.textColor = .darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "* Describe your item (5+ Words)" || textView.text == "" || (textView.text.trimmingCharacters(in: .whitespacesAndNewlines)) == "" {
            
            let partOne = NSMutableAttributedString(string: "*", attributes: [NSAttributedString.Key.foregroundColor : UIColor(red:0.72, green:0.00, blue:0.02, alpha:1.0), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)])
            let partTwo = NSMutableAttributedString(string: " Describe your item (5+ Words)", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)])
            
            partOne.append(partTwo)
            
            textView.attributedText = partOne
            
            self.lblItemDescriptionRange.text = "0/1000"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }else if textView.text.count >= 1000 && text != "" {
            return false
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
            self.lblItemDescriptionRange.text = "\(textView.text.count)/1000"
        })
        return true
    }
}
//MARK: -
extension AddSellItemVC : SelectCategoryProtocol {
    func selectCategory(_ category: String, andSubcategory subcategories: [String]) {
        self.categories = category
        self.subCategories = subcategories
//        self.subCategories.insert(self.categories, at: 0)
        self.lblCategory.text = category + " -> " + subcategories.joined(separator: ", ")
    }
}
//MARK: -
extension AddSellItemVC : SelectBrandProtocol {
    func selectBrand(withName brand: [String : Any]) {
        self.lblBrand.text = "\(brand["name"] ?? " ")"
    }
}
//MARK: - 
class SelectImageCollectionCell : UICollectionViewCell {
    
    @IBOutlet weak var imgItemPhoto: UIImageView!
    @IBOutlet weak var btnRemoveImage: UIButton!
}
