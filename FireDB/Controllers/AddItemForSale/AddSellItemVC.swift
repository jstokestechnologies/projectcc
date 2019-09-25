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

class AddSellItemVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var collectionCondition: UICollectionView!
    @IBOutlet weak var collectionImages: UICollectionView!
    
    @IBOutlet weak var imgItem: UIImageView!
    
    @IBOutlet weak var constCollectionImagesWidth: NSLayoutConstraint!
    
    @IBOutlet weak var txtItemName: UITextField!
    @IBOutlet weak var txtItemDescription: UITextView!
    @IBOutlet weak var txtItemPrice: UITextField!
    
    @IBOutlet weak var lblItemDescriptionRange: UILabel!
    @IBOutlet weak var lblItemNameRange: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var lblBrand: UILabel!
    
    @IBOutlet weak var btnPost: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var viewMaxImages: UIView!
    
    //MARK: - Properties
    let picker = UIImagePickerController()
    let arrConditions = [["title":"New","description":"New with tags (NWT). Unopened packaging. Unused."],
                         ["title":"Like New","description":"NNew without tags (NWOT). No signs of usage. Looks Unused."],
                         ["title":"Good","description":"Gently used having few minor scratches. Functioning properly."]]
    let maxImages = 5
    var arrImages = [ItemImages]()
    var arrRemovedImages = [ItemImages]()
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
    var selectedImageIndex = 0
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationImageSelected(_:)), name: Notification.Name.init(rawValue: kNotification_Image), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationCategoreySelected(_:)), name: Notification.Name.init(rawValue: kNotification_Category), object: nil)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.init(kNotification_Image), object: nil)
    }
    
    func prepareViews() {
        self.lblBrand.text = " "
        self.lblCategory.text = " "
        if isEditingItem {
            self.navigationItem.leftBarButtonItems = nil
            self.btnPost.setTitle("Update", for: .normal)
            self.btnPost.removeTarget(nil, action: nil, for: .allEvents)
            self.btnPost.addTarget(self, action: #selector(self.btnUpdateAction(_:)), for: .touchUpInside)
            if self.itemData != nil {
                self.setPreviousData()
            }else {
                self.fetchItemData()
            }
        }
        if self.arrImages.count > 0 {
            self.resizeImageCollection()
            self.setSelectedImage()
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
        
        // Price of the item
        self.lblPrice.text = "$\(self.itemData?.price ?? "")"
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
        
        // Add Images To Array
        for img in itemData?.item_images ?? [String]() {
            let itemImage = ItemImages()
            itemImage.imageUrl = img
            itemImage.action = .saved
            self.arrImages.append(itemImage)
        }
        self.resizeImageCollection()
        
        // Set first image
        let storageRef = storage.reference(withPath: (self.itemData?.item_images![0])!)
        self.imgItem.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        
        // Reload Collections
        self.collectionImages.reloadData()
        self.collectionCondition.reloadData()
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
            if self.validateProfileData() {
                self.itemType = .listedItems
                self.showSaveAlert(msg: "Are you sure you want to list this item for sale?")
            }else {
                self.showCompleteProfileAlert()
            }
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
        if let cell = sender.superview?.superview as? SelectImageCollectionCell {
            if let indexPath = self.collectionImages.indexPath(for: cell) {
                let alert = UIAlertController.init(title: "", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
                    self.removeImageWithIndex(index: indexPath.row)
                }))
                alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
                    
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnCloseAction(_ sender: UIButton) {
        self.view.endEditing(true)
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to close this window?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            self.navigationController?.dismiss(animated: true, completion: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name.init(kNotification_Category), object: nil)
//            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnUpdateAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.validateTextFields() {
            self.showSaveAlert(msg: "Are you sure you want to update?")
        }
    }
    
    @IBAction func notificationImageSelected(_ sender : Any) {
//        self.hideMainView(false)
        if let img = (sender as? Notification)?.userInfo?["image"] as? UIImage {
            let itemImage = ItemImages()
            itemImage.image = img
            itemImage.action = .new
            self.arrImages.append(itemImage)
            
            self.resizeImageCollection()
            
            self.setSelectedImage()
        }
    }
    
    @IBAction func notificationCategoreySelected(_ sender : Any) {
        self.category.removeAll()
        self.subCategory.removeAll()
        if let userInfo = (sender as? Notification)?.userInfo {
            if let catIds = userInfo["cat_ids"] as? [String], let cat_dict = userInfo["categories"] as? [String : [String : Any]] {
                if let cat = catIds.first, var cat_data = cat_dict[cat] {
                    cat_data["id"] = cat
                    self.category = cat_data
                }
                if catIds.count > 1 {
                    let catId = catIds[1]
                    if let cat_data = cat_dict[catId] {
                        self.subCategory[catId] = cat_data
                    }
                }
            }
//            cat["id"] = category.keys.first!
//            self.category = cat
//            self.subCategory = subcategories
            self.showCategoryAndSubCategory()
        }
    }
    
    //MARK: - Custom Methods
    func showCategoryAndSubCategory() {
        let strCatName = "\(self.category["name"] ?? "N/A")"
        var arrSubCatName = [""]
        if self.subCategory.values.count > 0 {
            arrSubCatName = self.subCategory.values.compactMap({"\($0["name"] ?? "-")"})
        }
        self.lblCategory.text = strCatName + " -> " + arrSubCatName.joined(separator: ", ")
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
        if self.arrImages.count <= 0 {
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
        }else if self.txtItemPrice.text!.count <= 0 {
            self.showAlert(msg: "Please enter item price.", isBack: false)
            return false
        }
        return true
    }
    
    func validateProfileData() -> Bool {
        if userdata.name.count <= 0 || (userdata.street?.count ?? 0) <= 0 || (userdata.city?.count ?? 0) <= 0 || (userdata.state?.count ?? 0) <= 0 {
            return false
        }else if (userdata.zipcode?.count ?? 0) <= 0 || (userdata.phone_number?.count ?? 0) <= 0 || (userdata.mpc?.count ?? 0) <= 0 || (userdata.sub_division?.count ?? 0) < 0 {
            return false
        }else {
            return true
        }
    }
    
    func getItemDetails() -> Dictionary<String,Any> {
        let timestamp =  Int64(Date().timeIntervalSince1970 * 1000)
        let imgPath = self.saveItemImages(timestamp)
        self.deleteRemovedImages()
//        if let savedImgs = self.itemData?.item_images, isEditingItem {
//            imgPath.append(contentsOf: savedImgs)
//        }
        let address = userdata.street! + " " + (userdata.city)! + " " + (userdata.state)! + " " + userdata.zipcode!
        let itemDetails : [String : Any] = ["item_name"     : (self.txtItemName.text)!,
                                            "description"   : (self.txtItemDescription.text)!,
                                            "category"      : self.category,
                                            "sub_category"  : Array(self.subCategory.keys),
                                            "brand"         : self.brand,
                                            "condition"     : "\(self.arrConditions[self.itemCondition]["title"] ?? "")",
                                            "price"         : (self.txtItemPrice.text)!,
                                            "user_id"       : userdata.id,
                                            "item_images"   : imgPath,
                                            "images_added"  : self.arrImages.count,
                                            "created"       : self.itemData?.created ?? timestamp,
                                            "updated"       : timestamp,
                                            "seller_name"   : userdata.name,
                                            "watchers"      : "",
                                            "used_category" : "",
                                            "home_address"  : address,
                                            "mpcName"       : userdata.mpc!,
                                            "subdivision"   : userdata.sub_division!,
                                            "buyerRating"   : "0",
                                            "sellerRating"  : "0",
                                            "bankAccountUpdated" : "0",
                                            "isPosted"      : self.itemType == .listedItems,
                                            "isArchived"     : false]
        return itemDetails
    }
    //+ userdata.city! + " " + userdata.state! + " " + userdata.zipcode
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
    
    func showAlert(msg : String, isBack : Bool) {
        let alert = UIAlertController.init(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (alrt) in
            if isBack {
                if self.isEditingItem {
                    self.navigationController?.popViewController(animated: true)
                }else {
                    if let tabVc = UIApplication.shared.keyWindow?.rootViewController as? TabBarVC {
                        tabVc.selectedIndex = 0
                    }
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showCompleteProfileAlert() {
//        let alert = UIAlertController.init(title: "", message: "Please update your profile to continue.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction.init(title: "Update", style: .default, handler: { (alrt) in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "EditProfileVC") as! EditProfileVC
            vc.delegate = self
            self.navigationController?.show(vc, sender: self)
//        }))
//        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (alrt) in
//
//        }))
//        self.present(alert, animated: true, completion: nil)
    }
    
    func saveItemImages(_ timestamp : Int64) -> [String] {
        var imgPaths = [String]()
        let arrNewImg = self.arrImages.filter({$0.action == .new && $0.image != nil})
        for i in 0..<arrNewImg.count {
            let imgCount = i + 1 + (self.itemData?.images_added ?? 0)
            let img = arrNewImg[i].image!
            let spaceRef = storage.reference().child("images/\(userdata.id)-\((Int(Date().timeIntervalSince1970 * 1000)))-\(imgCount).jpeg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imgData = img.jpegData(compressionQuality: 0.25)
            spaceRef.putData(imgData!, metadata: metadata)
            
            imgPaths.append(spaceRef.fullPath)
        }
        
        // Adding Previously saved image's path
        let arrSavedImg = self.arrImages.filter({$0.action == .saved && $0.imageUrl != nil})
        let arrSavedImgPath = arrSavedImg.map({$0.imageUrl!})
        imgPaths.append(contentsOf: arrSavedImgPath)
        
        return imgPaths
    }
    
    func deleteRemovedImages() {
        for img in self.arrRemovedImages {
            let storageRef = storage.reference()
            let desertRef = storageRef.child(img.imageUrl!)
            
            //Removes image from storage
            desertRef.delete { error in
                if let error = error {
                    print(error)
                } else {
                    // File deleted successfully
                }
            }
        }
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
    
    func setSelectedImage() {
        let selectedImage = self.arrImages[self.selectedImageIndex]
        if selectedImage.image != nil {
            self.imgItem.image = selectedImage.image
        }else if selectedImage.imageUrl != nil {
            let storageRef = storage.reference(withPath: selectedImage.imageUrl!)
            self.imgItem.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        }
    }
    
    func resizeImageCollection() {
        if self.arrImages.count > 0 {
            var width = CGFloat(((self.arrImages.count + 1) * 88) + 10)
            if width > self.view.frame.width {
                width = self.view.frame.width
            }
            self.constCollectionImagesWidth.constant = width
        }else {
            self.constCollectionImagesWidth.constant = 98.0
        }
        self.viewMaxImages.isHidden = self.arrImages.count < self.maxImages
        self.collectionImages.reloadData()
    }
    
    func removeImageWithIndex(index : Int) {
        let image = self.arrImages[index]
        if image.action == .saved {
            self.arrRemovedImages.append(image)
        }
        self.arrImages.remove(at: index)
        
        self.resizeImageCollection()
        
        if self.selectedImageIndex >= index {
            self.selectedImageIndex -= 1
        }
        if self.selectedImageIndex >= 0 {
            self.setSelectedImage()
        }else {
            self.selectedImageIndex = 0
            if self.arrImages.count > 0 {
                self.setSelectedImage()
            }else {
                self.imgItem.image = UIImage.init(named: "no-image")
            }
        }
    }
    
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSelectCategory" {
            let vc = segue.destination as! SelectCategoryVC
            vc.collectionName = "categories"
            vc.delegate = self
        }else if segue.identifier == "segueSelectBrand" {
            let vc = segue.destination as! SelectBrandVC
            vc.delegate = self
        }
    }
}

//MARK: - CollectionView Delegate
extension AddSellItemVC : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionCondition {
            return self.arrConditions.count
        }
        
        return self.arrImages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var identifier = ""
        if collectionView == self.collectionCondition {
            identifier = "CellCondition"
        }else {
            if (indexPath.row ) == self.arrImages.count {
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
        
        if let cell = cell as? SelectImageCollectionCell {
            let borderColor = (UIColor.init(patternImage: UIImage.init(named: "border_dot.png")!)).cgColor
            if indexPath.row < self.arrImages.count {
                cell.imgItemPhoto?.layer.borderColor = borderColor
                let itemImage = self.arrImages[indexPath.row]
                
                if itemImage.image != nil {
                    cell.imgItemPhoto.image = itemImage.image
                }else {
                    let storageRef = storage.reference(withPath: itemImage.imageUrl!)
                    cell.imgItemPhoto.image = UIImage.init(named: "no-image")
                    cell.imgItemPhoto.sd_setImage(with: storageRef, maxImageSize: 500, placeholderImage: UIImage.init(named: "no-image")) { (img, err, catcheType, ref) in
                        itemImage.image = img
                    }
                }
                cell.btnRemoveImage.addTarget(self, action: #selector(self.btnRemoveImageAction(_:)), for: .touchUpInside)
            }else {
                cell.viewBackground?.layer.borderColor = borderColor
            }
            
            return cell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let totalImages = self.arrImages.count
        if collectionView == self.collectionCondition {
            self.itemCondition = indexPath.row
            self.collectionCondition.reloadData()
        }else {
            if totalImages == indexPath.row && totalImages < self.maxImages {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomCameraVC") as! CustomCameraVC
                vc.isFirstVC = false
                vc.modalPresentationStyle = .custom
                self.present(vc, animated: true, completion: nil)
            }else if indexPath.row < totalImages {
                let cell = collectionView.cellForItem(at: indexPath) as! SelectImageCollectionCell
                self.imgItem.image = cell.imgItemPhoto.image
                self.selectedImageIndex = indexPath.row
            }else if totalImages == self.maxImages {
                HelperClass.showAlert(msg: "You can select maximum of 5 images.", isBack: false, vc: self)
            }
        }
    }
}

//MARK: - Pick Images
extension AddSellItemVC : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.editedImage] as? UIImage {
            let itemImage = ItemImages()
            itemImage.image = img
            itemImage.action = .new
            self.arrImages.append(itemImage)
        }else if let img = info[.originalImage] as? UIImage {
            let itemImage = ItemImages()
            itemImage.image = img
            itemImage.action = .new
            self.arrImages.append(itemImage)
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
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" && textField == self.txtItemName {
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
                let myDouble = Double(textField.text!)
                let price = String(format: "%.2f", myDouble ?? 0.0)
                self.lblPrice.text = "$\(price)"
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

extension AddSellItemVC : UpdateProfileDelegate {
    func userUpdatedProfile(success: Bool) {
        if success && self.validateProfileData() && self.validateTextFields() {
            self.itemType = .listedItems
            self.saveData()
//            self.showSaveAlert(msg: "Are you sure you want to list this item for sale?")
        }
    }
}

//MARK: - 
class SelectImageCollectionCell : UICollectionViewCell {
    @IBOutlet weak var viewBackground: UIView?
    @IBOutlet weak var imgItemPhoto: UIImageView!
    @IBOutlet weak var btnRemoveImage: UIButton!
}

