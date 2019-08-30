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
    
    @IBOutlet weak var viewUpdate: UIView!
    
    
    //MARK: - Properties
    let picker = UIImagePickerController()
    let arrConditions = [["title":"New","description":"New with tags (NWT). Unopened packaging. Unused."],
                         ["title":"Like New","description":"NNew without tags (NWOT). No signs of usage. Looks Unused."],
                         ["title":"Good","description":"Gently used having few minor scratches. Functioning properly."]]
    let maxImages = 8
    var arrItemImages = Array<UIImage>()
    var itemCondition = 0
    var categories = String()
    var category = [String : Any]()
    var subCategory = [String : [String : Any]]()
    var brand = [String : Any]()
    
    lazy var storage = Storage.storage()
    
    //On Edit Item
    var removedImages = Array<String>()
    var isEditingItem = false
    var itemId = String()
    var itemData : ItemsDetail?
    
    enum ItemsListType {
        case savedItems
        case listedItems
    }
    var itemType = ItemsListType.listedItems
    
    
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
        
        if isEditingItem {
            if self.itemData != nil {
                self.setPreviousData()
            }else {
                self.fetchItemData()
            }
            self.viewUpdate.isHidden = false
            let fView = self.tableView.tableFooterView
            fView?.frame.size.height = 80
            self.tableView.tableFooterView = fView
            self.tableView.reloadData()
        }
    }
    
    func setPreviousData() {
        // Set name of the item
        self.txtItemName.text = self.itemData?.item_name
        self.txtItemName.textColor = .darkGray
        self.lblItemNameRange.text = "\(self.txtItemName.text!.count)/40"
        
        // Set description of the item
        self.txtItemDescription.text = self.itemData?.description
        self.txtItemDescription.textColor = .darkGray
        self.lblItemDescriptionRange.text = "\(self.txtItemDescription.text!.count)/1000"
        
        // Set Color and Price of the item
        self.lblItemColor.text = self.itemData?.color
        self.lblPrice.text = self.itemData?.price
        self.txtItemPrice.text = self.itemData?.price
        
        // Set brand and category of the item
        self.brand = (self.itemData?.brand)!
        self.lblBrand.text = self.itemData?.brand?["name"]
        self.category = (self.itemData?.category)!
        
        // Fetch Category and subcategories of the item
        self.getPreviousSubcategory()
        
        // Set item condition
        let conditionIndex = self.arrConditions.firstIndex(where: {"\($0["title"] ?? "")" == self.itemData?.condition ?? ""})
        self.itemCondition = conditionIndex ?? 0
        
        // Reload Collections
        self.collectionImages.reloadData()
        self.collectionCondition.reloadData()
    }
    
    func getPreviousSubcategory() {
        let concurrentQueue = DispatchQueue(label: "com.queue.Concurrent", attributes: .concurrent)
        let group = DispatchGroup()
        
        // Fetch all the subcategories
        if let subCats = self.itemData?.sub_category {
            for subCat in subCats {
                group.enter()
                concurrentQueue.async {
                    self.fetchDataFromFirebase(collectionRef: "subcategories", docRef: "\(subCat)", completion: { (cat) in
                        self.subCategory[subCat] = ["name" : cat]
                        group.leave()
                    })
                }
            }
        }
        
        // Notify when done fetching category and subcategories both
        group.notify(queue: DispatchQueue.main) {
            self.showCategoryAndSubCategory()
        }
    }
    
    func showCategoryAndSubCategory() {
        let strCatName = "\(self.category["name"] ?? "N/A")"
        var arrSubCatName = [""]
        if self.subCategory.values.count > 0 {
            arrSubCatName = self.subCategory.values.compactMap({"\($0["name"] ?? "-")"})
        }
        self.lblCategory.text = strCatName + " -> " + arrSubCatName.joined(separator: ", ")
    }
    
    //MARK: - Firebase Methods
    func fetchItemData() {
        progressView.showActivity()
        let itemRef = db.collection(kListedItems).document("/\(itemId)")
        itemRef.getDocument { (doc, err) in
            if let data = doc?.data() {
                do {
                    let jsonData  = try? JSONSerialization.data(withJSONObject: data, options:.prettyPrinted)
                    let jsonDecoder = JSONDecoder()
                    //                                    var userdata = UserData.sharedInstance
                    self.itemData = try jsonDecoder.decode(ItemsDetail.self, from: jsonData!)
                    self.setPreviousData()
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            progressView.hideActivity()
        }
    }
    
    func fetchDataFromFirebase(collectionRef : String, docRef : String, completion : @escaping (String) -> () ) {
        let itemRef = db.collection(collectionRef).document("/\(docRef)")
        itemRef.getDocument { (doc, err) in
            if let data = doc?.data() {
                completion(data["name"] as? String ?? "")
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func btnListAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
            self.itemType = .listedItems
            self.showSaveAlert(msg: "Are you sure you want to list this item for sale?")
        }
    }
    
    @IBAction func btnSaveDraftAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
            self.itemType = .savedItems
            self.showSaveAlert(msg: "Are you sure you want to save this item in draft?")
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
    
    @IBAction func btnUpdateAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
            self.showSaveAlert(msg: "Are you sure you want update?")
        }
    }
    
    //MARK: - Other
    func showSaveAlert(msg : String) {
        let alert = UIAlertController.init(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            self.saveData()
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveData() {
        progressView.showActivity()
        if isEditingItem {
            self.saveEditedItemDetails(itemData: self.getItemDetails()) { (err, success) in
                if success {
                    self.showAlert(msg: "Item details saved successfully", isBack: true)
                }
                progressView.hideActivity()
            }
        }else {
            self.saveItemDetails(itemData: self.getItemDetails()) { (err, success) in
                if success {
                    self.showAlert(msg: "Item details saved successfully", isBack: true)
                }
                progressView.hideActivity()
            }
        }
    }
    
    func validateTextFields() -> Bool {
        if self.arrItemImages.count <= 0 && !self.isEditingItem {
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
        }else if self.lblItemColor.text!.count < 2 {
            self.showAlert(msg: "Please enter color.", isBack: false)
            return false
        }else if self.txtItemPrice.text!.count <= 0 {
            self.showAlert(msg: "Please enter item price.", isBack: false)
            return false
        }
        return true
    }
    
    func getItemDetails() -> Dictionary<String,Any> {
        let timestamp =  Int64(Date().timeIntervalSince1970 * 1000)
        var imgPath = self.saveItemImages(timestamp)
        if let savedImgs = self.itemData?.item_images, isEditingItem {
            imgPath.append(contentsOf: savedImgs)
        }
        
        let itemDetails : [String : Any] = ["item_name"     : (self.txtItemName.text)!,
                                            "description"   : (self.txtItemDescription.text)!,
                                            "category"      : self.category,
                                            "sub_category"  : Array(self.subCategory.keys),
                                            "brand"         : self.brand,
                                            "condition"     : "\(self.arrConditions[self.itemCondition]["title"] ?? "")",
                                            "color"         : (self.lblItemColor.text)!,
                                            "price"         : (self.txtItemPrice.text)!,
                                            "user_id"       : userdata.id,
                                            "item_images"   : imgPath,
                                            "images_added"  : self.arrItemImages.count + (self.itemData?.images_added ?? 0),
                                            "created"       : self.itemData?.created ?? timestamp,
                                            "updated"       : timestamp,
                                            "seller_name"   : userdata.name,
                                            "watchers"      : "",
                                            "used_category" : "",
                                            "home_address"  : "",
                                            "mpcName"       : "",
                                            "subdivision"   : "",
                                            "buyerRating"   : "0",
                                            "sellerRating"  : "0",
                                            "bankAccountUpdated" : "0",
                                            "isPosted"      : self.itemType == .listedItems,
                                            "isArchived"     : false]
        return itemDetails
    }
    
    func saveItemDetails(itemData : Dictionary<String,Any>, completionHandler:@escaping (Error?, Bool) -> ()) {
        var ref: DocumentReference? = nil
        ref = db.collection(kListedItems).addDocument(data: itemData) { err in
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
                if self.isEditingItem {
                    self.navigationController?.popViewController(animated: true)
                }else {
                    let tabBarVC = self.tabBarController
                    self.navigationController?.setViewControllers([(self.storyboard?.instantiateViewController(withIdentifier: "AddSellItemVC"))!], animated: false)
                    tabBarVC?.selectedIndex = 0
                }
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func saveItemImages(_ timestamp : Int64) -> [String] {
        var imgPaths = [String]()
        
        for i in 0..<self.arrItemImages.count {
            let imgCount = i + 1 + (self.itemData?.images_added ?? 0)
            let img = self.arrItemImages[i]
            let spaceRef = storage.reference().child("images/\(userdata.id)-\((Int(Date().timeIntervalSince1970 * 1000)))-\(imgCount).jpeg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imgData = img.jpegData(compressionQuality: 0.25)
            spaceRef.putData(imgData!, metadata: metadata)
            
            imgPaths.append(spaceRef.fullPath)
        }
        
        return imgPaths
    }
    
    func saveEditedItemDetails(itemData : Dictionary<String,Any>, completionHandler:@escaping (Error?, Bool) -> ()) {
        db.collection(kListedItems).document(self.itemId).setData(itemData) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completionHandler(err, false)
            }else {
                print("Document added\n\n\n\n\n")
                completionHandler(err, true)
            }
        }
    }
    
    func showColorTextView() {
        let alert = UIAlertController.init(title: "", message: "Enter Color", preferredStyle: .alert)
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "Enter color name"
            textfield.font = UIFont.systemFont(ofSize: 15)
            textfield.textColor = .black
            textfield.keyboardType = .asciiCapable
            textfield.text = self.lblItemColor.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (alrt) in
            self.lblItemColor.text = alert.textFields?.first?.text
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSelectCategory" {
            let vc = segue.destination as! SelectCategoryVC
            if self.subCategory.keys.count > 0 {
                vc.previousCategory = ["\(self.category["id"] ?? "")" :  self.category]
                vc.arrPreviousSubCat = Array(self.subCategory.keys)
            }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            self.showColorTextView()
        }
    }
}

//MARK: - CollectionView Delegate
extension AddSellItemVC : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionCondition {
            return self.arrConditions.count
        }
        var count = (self.itemData?.item_images?.count ?? 0) + self.arrItemImages.count + 1
        count = count > maxImages ? maxImages : count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let totalImages = (self.itemData?.item_images?.count ?? 0) + self.arrItemImages.count
        var identifier = ""
        if collectionView == self.collectionCondition {
            identifier = "CellCondition"
        }else {
            if indexPath.row == totalImages {
                identifier = "CellAdd"
            }else {
                identifier = "CellImage"
            }
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        if collectionView == self.collectionCondition {
            (cell.viewWithTag(1) as! UILabel).text = "\(self.arrConditions[indexPath.row]["title"] ?? "New")"
            (cell.viewWithTag(2) as! UILabel).text = "\(self.arrConditions[indexPath.row]["description"] ?? "New")"
            let borderColor = self.itemCondition == indexPath.row ? UIColor.blue.cgColor : UIColor.lightGray.cgColor
            cell.layer.borderColor = borderColor
            return cell
        }
        
        let borderColor = (UIColor.init(patternImage: UIImage.init(named: "border_dot.png")!)).cgColor
        cell.layer.borderColor = borderColor
        
        if indexPath.row < totalImages {
            if indexPath.row < (self.itemData?.item_images?.count ?? 0) {
                let storageRef = storage.reference(withPath: (self.itemData?.item_images![indexPath.row])!)
                (cell.viewWithTag(11) as! UIImageView).image = UIImage.init(named: "no-image")
                (cell.viewWithTag(11) as! UIImageView).sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
            }else {
                (cell.viewWithTag(11) as! UIImageView).image = self.arrItemImages[indexPath.row - (self.itemData?.item_images?.count ?? 0)]
//                (cell.contentView.viewWithTag(101) as! UIButton).tag = indexPath.row
                (cell.contentView.viewWithTag(101) as! UIButton).addTarget(self, action: #selector(self.btnRemoveImageAction(_:)), for: .touchUpInside)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let totalImages = (self.itemData?.item_images?.count ?? 0) + self.arrItemImages.count
        if collectionView == self.collectionCondition {
            self.itemCondition = indexPath.row
            self.collectionCondition.reloadData()
        }else {
            if totalImages == indexPath.row && totalImages < self.maxImages {
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
    func selectCategory(_ category: [String : [String : Any]], andSubcategory subcategories: [String : [String : Any]]) {
        var cat = category.values.first!
        cat["id"] = category.keys.first!
        self.category = cat
        self.subCategory = subcategories
        self.showCategoryAndSubCategory()
    }
}
//MARK: -
extension AddSellItemVC : SelectBrandProtocol {
    func selectBrand(withName brand:[String : Any]) {
        self.lblBrand.text = "\(brand["name"] ?? " ")"
        self.brand = brand
    }
}
//MARK: - 
class SelectImageCollectionCell : UICollectionViewCell {
    
    @IBOutlet weak var imgItemPhoto: UIImageView!
    @IBOutlet weak var btnRemoveImage: UIButton!
}
