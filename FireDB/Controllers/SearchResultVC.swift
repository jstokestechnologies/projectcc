//
//  SearchResultVC.swift
//  FireDB
//
//  Created by admin on 01/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

class SearchResultVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var tblItemList: UITableView!
    
    
    //MARK: - Variables
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    var refId = ""
    var keyName = ""
    var isSubcategory = false
    var titles = ""
    
    var pageNo = 1
    var itemPerPage = 10
    var isNextPage = true
    var lastDoc : DocumentSnapshot?
    var arrItemIds = [String]()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        if self.keyName.count > 0 {
            self.fetchItemList()
        }else {
            if self.arrItemIds.count > 0 {
                self.fetchItemsWithSimilarName()
            }else {
                self.fetchSearchedItem()
            }
        }
        // Do any additional setup after loading the view.
        tblItemList.register(UINib(nibName: "ItemCardTableCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func initialSetup() {
        self.title = titles
    }
    
    //MARK: - Firebase Methods
    func fetchSearchedItem() {
        let query = db.collection(kListedItems).document(self.refId)
        
        query.getDocument { (doc, err) in
            if let document = doc {
                guard var dict =  document.data() else { return }
                dict["id"] = document.documentID
                self.parseFireBaseData(arr: [dict])
            }
            progressView.hideActivity()
        }
    }
    
    func fetchItemList() {
        var query : Query? = db.collection(kListedItems)
        if self.isSubcategory {
            query = query?.whereField(self.keyName, arrayContains: self.refId).limit(to: self.itemPerPage)
        }else {
            query = query?.whereField(self.keyName, isEqualTo: self.refId).limit(to: self.itemPerPage)
        }
        if self.pageNo > 1 && self.lastDoc != nil {
            query = query?.start(afterDocument: self.lastDoc!)
        }
        
        query?.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                self.lastDoc = documents.last
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                self.parseFireBaseData(arr: arr)
            }
            progressView.hideActivity()
        }
    }
    
    func fetchItemsWithSimilarName() {
        self.arrItems?.removeAll()
        if userdata.my_bookmarks?.count ?? 0 > 0 {
            let reqParam = ["documents" : self.arrItemIds.compactMap({"projects/projectcc-a98a4/databases/(default)/documents/listed_items/\($0)"}),
                            "newTransaction"  : NSDictionary()] as [String : Any]
            HelperClass.requestForAllApiWithBody(param: reqParam as NSDictionary, serverUrl: "https://firestore.googleapis.com/v1beta1/projects/projectcc-a98a4/databases/(default)/documents:batchGet", vc: self) { (itemData, msg, status) in
                if var arrItems = itemData["array"] as? Array<Any> , arrItems.count > 1 {
                    arrItems.remove(at: 0)
                    let arr = arrItems.map({(($0 as? NSDictionary)?.object(forKey: "found") as? NSDictionary)?.object(forKey: "fields") })
                    
                    for i in 0..<arr.count {
                        var itemId = (((arrItems[i]) as? NSDictionary)?.object(forKey: "found") as? NSDictionary)?.value(forKey: "name") as? String
                        itemId = itemId?.components(separatedBy: "/").last
                        
                        let item = arr[i]
                        if let itemDict = item as? NSDictionary {
                            self.addNewItemToListWithData(itemDict: itemDict, itemId: itemId)
                        }
                    }
                    self.tblItemList.reloadData()
                }
                self.setNoDataLabel()
                progressView.hideActivity()
            }
        }else {
            self.setNoDataLabel()
            progressView.hideActivity()
            self.tblItemList.reloadData();
        }
    }
    
    func saveBookmarkedItemId(itemId : String) {
        db.collection("Users").document(userdata.id).setData(["my_bookmarks" : FieldValue.arrayUnion([itemId])], merge: true) { (err) in
            if (err != nil) {
                HelperClass.showAlert(msg: err?.localizedDescription ?? "Failed to update changes", isBack: false, vc: self)
            }else {
                userdata.my_bookmarks?.append(itemId)
                self.saveBookmarksToUserDefaults()
            }
        }
    }
    
    func removeBookmarkedItemId(itemId : String) {
        db.collection("Users").document(userdata.id).setData(["my_bookmarks" : FieldValue.arrayRemove([itemId])], merge: true) { (err) in
            if (err != nil) {
                HelperClass.showAlert(msg: err?.localizedDescription ?? "Failed to update changes", isBack: false, vc: self)
            }else {
                userdata.my_bookmarks?.removeAll(where: {$0 == itemId})
                self.saveBookmarksToUserDefaults()
            }
        }
    }
    
    //MARK: - Parse Data
    func parseFireBaseData(arr : [[String : Any]] ) {
        do {
            let jsonData  = try? JSONSerialization.data(withJSONObject: arr, options:.prettyPrinted)
            let jsonDecoder = JSONDecoder()
            let arrItemData = try jsonDecoder.decode([ItemsDetail].self, from: jsonData!)
            if self.arrItems == nil || self.pageNo <= 1 {
                self.arrItems = arrItemData
            }else {
                self.arrItems?.append(contentsOf: arrItemData)
            }
            self.changePageNumber()
            DispatchQueue.main.async {
                self.setNoDataLabel()
                self.tblItemList.reloadData()
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func addNewItemToListWithData(itemDict : NSDictionary, itemId : String?) {
        let itemObj = ItemsDetail()
        itemObj.item_name = "\((itemDict.value(forKey: "item_name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        itemObj.price = "\((itemDict.value(forKey: "price") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        let brand = ((itemDict.value(forKey: "brand") as? NSDictionary)?.object(forKey: "mapValue") as? NSDictionary)?.object(forKey: "fields") as? NSDictionary
        itemObj.brand = ["id" :  "\((brand?.object(forKey: "id") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "name" :  "\((brand?.object(forKey: "name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "user" :  "\((brand?.object(forKey: "user") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"]
        
        let imagesData = ((itemDict.value(forKey: "item_images") as? NSDictionary)?.object(forKey: "arrayValue") as? NSDictionary)?.object(forKey: "values") as? [NSDictionary]
        let arrImages = imagesData?.compactMap({"\($0.value(forKey: "stringValue") ?? "")"})
        
        itemObj.item_images = arrImages
        itemObj.images_added = itemObj.item_images?.count ?? 0
        itemObj.id = itemId
        
        if self.arrItems == nil {
            self.arrItems = [itemObj]
        }else {
            if (self.arrItems?.count ?? 0) > 0 && (self.refId == itemObj.id ?? "") {
                self.arrItems?.insert(itemObj, at: 0)
            }else {
                self.arrItems?.append(itemObj)
            }
        }
    }
    
    //MARK: - IBAction Methods
    @IBAction func btnBookmarkAction(_ sender: UIButton) {
        if let itemId = self.arrItems?[sender.tag].id {
            var imgName = "bookmark_outline"
            if userdata.my_bookmarks?.contains(itemId) ?? false {
                self.removeBookmarkedItemId(itemId: itemId)
            }else {
                self.saveBookmarkedItemId(itemId: itemId)
                imgName = "bookmark_filled"
            }
            UIView.transition(with: sender as UIView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                sender.setImage(UIImage(named: imgName), for: .normal)
            }, completion: nil)
        }
    }
    
    //MARK: - Custom methods
    func saveBookmarksToUserDefaults() {
        let userDict = HelperClass.fetchDataFromDefaults(with: kUserData).mutableCopy() as! NSMutableDictionary
        userDict["my_bookmarks"] = userdata.my_bookmarks
        HelperClass.saveDataToDefaults(dataObject: userDict, key: kUserData)
    }
    
    func setNoDataLabel() {
        if self.arrItems?.count ?? 0 <= 0 {
            let lbl = UILabel()
            lbl.text = "No items found"
            lbl.textAlignment = .center
            lbl.sizeToFit()
            lbl.frame.size.height = 60
            self.tblItemList.tableFooterView = lbl
        }else {
            self.tblItemList.tableFooterView = UIView.init(frame: CGRect.zero)
        }
    }
    
    func changePageNumber() {
        if (self.arrItems?.count ?? 0) < (self.pageNo*self.itemPerPage) {
            self.isNextPage = false
        }else {
            self.isNextPage = true
        }
        self.pageNo += 1
    }
    
    /*
     // MARK - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     
     }
     */
    
}

// MARK: -
extension SearchResultVC : UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemListCell
        let item = self.arrItems![indexPath.row]
        
        cell.lblItemName.text = item.item_name
        cell.lblItemBrand.text = item.brand?["name"]
        //        cell.lblDesciption.text = item.description
        cell.lblItemPrice.text = "$\(item.price ?? "0.00")"
        cell.lblSubDivision.text = item.subdivision ?? "N/A"
        
        cell.pageImgPages.numberOfPages = item.item_images?.count ?? 0
        cell.pageImgPages.isHidden = (item.item_images?.count ?? 0) <= 1
        
        cell.collectionImages.register(ItemImagesCollectionCell.classForCoder(), forCellWithReuseIdentifier: "CellItemImage")
        cell.collectionImages.dataSource = self
        cell.collectionImages.delegate = self
        cell.collectionImages.tag = indexPath.row
        cell.collectionImages.allowsSelection = false
        cell.collectionImages.reloadData()
        cell.btnBookmark.tag = indexPath.row
        cell.btnBookmark.addTarget(self, action: #selector(self.btnBookmarkAction(_:)), for: .touchUpInside)
        if userdata.my_bookmarks?.contains(item.id ?? " ") ?? false {
            cell.btnBookmark.setImage(UIImage.init(named: "bookmark_filled"), for: .normal)
        }else {
            cell.btnBookmark.setImage(UIImage.init(named: "bookmark_outline"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500.00
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print(indexPaths)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.arrItemIds.count <= 0 {
            let scrollViewHeight = scrollView.frame.size.height
            let scrollContentSizeHeight = scrollView.contentSize.height
            let scrollOffset = scrollView.contentOffset.y
            if ((scrollOffset + scrollViewHeight) >= (scrollContentSizeHeight - 500)) && self.isNextPage
            {
                self.fetchItemList()
                self.isNextPage = false
            }
        }
    }
    
}

// MARK: -
extension SearchResultVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let item = self.arrItems![collectionView.tag]
        return item.item_images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellItemImage", for: indexPath) as! ItemImagesCollectionCell
        let imgView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.size.height))
        imgView.contentMode = .scaleAspectFill
        cell.addSubview(imgView)
        
        let item = self.arrItems![collectionView.tag]
        let storageRef = storage.reference(withPath: item.item_images![indexPath.row])
        imgView.image = UIImage.init(named: "no-image")
        imgView.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width, height: collectionView.frame.size.height)
    }
    
}
