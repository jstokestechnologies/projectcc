//
//  ItemListForSaleVC.swift
//  FireDB
//
//  Created by admin on 12/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI


class ItemListForSaleVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var tblItemList: UITableView!
    
    @IBOutlet weak var btnListedItems: UIButton!
    @IBOutlet weak var btnSavedItems: UIButton!
    @IBOutlet weak var btnNewPosts: UIButton!
    @IBOutlet weak var btnFilter: UIView!
    @IBOutlet weak var btnSort: UIView!
    
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //MARK: - Variables
    var arrItems : [ItemsDetail]?
    var arrNewItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    var refreshControl = UIRefreshControl()
    var pageNo = 1
    var itemPerPage = 3
    var isNextPage = true
    var lastDoc : DocumentSnapshot?
    var listner : ListenerRegistration?
    var latestTime = 0
    
    // Search
    var isSearching = false
    var searchItem = SearchItem()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        if self.tabBarController?.selectedIndex == 0 {
            progressView.showActivity()
            NotificationCenter.default.addObserver(self, selector: #selector(self.notificationPaySuccess(_:)), name: NSNotification.Name(kNotification_PaySuccess), object: nil)
            self.fetchItemList()
        }else {
            self.title = "Favorites"
            self.viewSearch.isHidden = true
        }
        // Do any additional setup after loading the view.
        tblItemList.register(UINib(nibName: "ItemCardTableCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.tabBarController?.selectedIndex == 3 {
            progressView.showActivity()
            self.arrItems = [ItemsDetail]()
            self.fetchBookmarkedItems()
        }else {
            self.addNewItemToList(scrollToTop: true)
//            self.fetchItemList()
        }
    }
    
    func initialSetup() {
        self.btnFilter.semanticContentAttribute = .forceRightToLeft
        
        self.latestTime = Int(Date().timeIntervalSince1970 * 1000)
        if self.tabBarController?.selectedIndex == 0 {
            self.tabBarController?.delegate = self
        }
        
        DispatchQueue.main.async {
            self.viewSearch.frame.size.width = self.view.frame.width - 40
        }
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: UIControl.Event.valueChanged)
        self.tblItemList.addSubview(refreshControl)
        
        self.btnListedItems.layer.borderColor = UIColor.lightGray.cgColor
        self.btnSavedItems.layer.borderColor = UIColor.lightGray.cgColor
        if userdata.my_bookmarks == nil {
            userdata.my_bookmarks = [String]()
        }
    }
    
    //MARK: - Firebase Methods
    func fetchBookmarkedItems() {
        self.arrItems?.removeAll()
        if userdata.my_bookmarks?.count ?? 0 > 0 {
            let reqParam = ["documents" : userdata.my_bookmarks?.compactMap({"projects/projectcc-a98a4/databases/(default)/documents/listed_items/\($0)"}) ?? " ",
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
                self.refreshControl.endRefreshing()
            }
        }else {
            self.setNoDataLabel()
            progressView.hideActivity()
            self.refreshControl.endRefreshing()
            self.tblItemList.reloadData();
        }
    }
    
    func fetchItemList() {
        var query = db.collection(kListedItems).whereField("isPosted", isEqualTo: true).whereField("isArchived", isEqualTo: false).order(by: "created", descending: true).whereField("created", isLessThanOrEqualTo: self.latestTime).limit(to: self.itemPerPage)
        if self.pageNo > 1 && self.lastDoc != nil {
            query = query.start(afterDocument: self.lastDoc!)
        }
        query.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                self.lastDoc = documents.last
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                self.setTableFooter(count: arr.count + (self.arrItems?.count ?? 0))
                self.parseFireBaseData(arr: arr)
                self.changePageNumber()
//                self.arrItems?.removeAll(where: { (item) -> Bool in
//                    return item.isPaid ?? false
//                })
            }else {
                self.isNextPage = false
            }
            progressView.hideActivity()
            self.refreshControl.endRefreshing()
        }
    }
    
    func addListnerOnNewEntry() {
        listner = db.collection(kListedItems).addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if self.tblItemList.tag == 0 {
                self.tblItemList.tag = 10000
                return
            }
            snapshot.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    var dict =  diff.document.data()
                    dict["id"] = diff.document.documentID
                    let arr = [dict]
                    do {
                        let jsonData  = try? JSONSerialization.data(withJSONObject: arr, options:.prettyPrinted)
                        let jsonDecoder = JSONDecoder()
                        let arrItemData = try jsonDecoder.decode([ItemsDetail].self, from: jsonData!)
                        if self.arrNewItems != nil {
                            self.arrNewItems?.insert(contentsOf: arrItemData, at: 0)
                        }else {
                            self.arrNewItems = arrItemData
                        }
                        self.btnNewPosts.isHidden = false
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                }
            }
            
        }
    }
    
    func parseFireBaseData(arr : [[String : Any]] ) {
        do {
            let jsonData  = try? JSONSerialization.data(withJSONObject: arr, options:.prettyPrinted)
            let jsonDecoder = JSONDecoder()
            //                                    var userdata = UserData.sharedInstance
            let arrItemData = try jsonDecoder.decode([ItemsDetail].self, from: jsonData!)
            if self.arrItems == nil || self.pageNo <= 1 {
                if self.listner == nil {
                    self.addListnerOnNewEntry()
                }
                self.arrItems = arrItemData
            }else {
                self.arrItems?.append(contentsOf: arrItemData)
            }
            DispatchQueue.main.async {
                self.tblItemList.reloadData()
            }
        }
        catch {
            print(error.localizedDescription)
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
    
    func savePaymentDetails(itemId : String, details : [String : Any]) {
        db.collection(kListedItems).document(itemId).setData(details, merge: true)
    }
    
    //MARK: - Button IBAction
    @IBAction func btnLogoutAction(_ sender: Any) {
        self.view.endEditing(true)
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to logout?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            UserDefaults.standard.removeObject(forKey: kUserData)
            UserDefaults.standard.set(false, forKey: kIsLoggedIn)
            UserDefaults.standard.synchronize()
            userdata = UserData()
            UIApplication.shared.keyWindow?.rootViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LoginNavVC")
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnAddItemForSaleAction(_ sender: Any) {
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "AddSellItemVC")
        let navVC = UINavigationController.init(rootViewController: vc)
        navVC.navigationBar.tintColor = .darkGray
        self.present(navVC, animated: true, completion: nil)
    }
    
    @IBAction func btnShowMyListedItemsAction(_ sender: Any) {
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
        vc.listType = .listedItems
        self.navigationController?.show(vc, sender: self)
    }
    
    @IBAction func btnShowMySavedItemsAction(_ sender: Any) {
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
        vc.listType = .savedItems
        self.navigationController?.show(vc, sender: self)
    }
    
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
    
    @IBAction func btnNewPostsAction(_ sender: UIButton) {
        self.addNewItemToList(scrollToTop: true)
    }
    
    @IBAction func btnSearchAction(_ sender: UIButton) {
        let vc = secondStoryBoard.instantiateViewController(withIdentifier: "SearchNavVC")
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        
        let transition: CATransition = CATransition()
        transition.duration = 0.4
        transition.type = CATransitionType.fade
        transition.subtype = CATransitionSubtype.fromTop
        self.view.window?.layer.add(transition, forKey: nil)
        
        self.present(vc, animated: false, completion: nil)
    }
    
    @IBAction func pullToRefresh(_ sender : Any) {
        if self.tabBarController?.selectedIndex == 3 {
            progressView.showActivity()
            self.arrItems = [ItemsDetail]()
            self.fetchBookmarkedItems()
        }else {
            self.lastDoc = nil
            self.pageNo = 1
            self.isNextPage = false
            self.latestTime = Int(Date().timeIntervalSince1970 * 1000)
            self.fetchItemList()
        }
    }
    
    @IBAction func btnBuyAction(_ sender : UIButton) {
        let item = self.arrItems?[sender.tag]
        let vc = secondStoryBoard.instantiateViewController(withIdentifier: "PaymentVC") as! PaymentVC
        vc.amount = Int((Double(item?.price ?? "0.0") ?? 0.0) * 100.0)
        guard let itemId = item?.id else {
            return
        }
        vc.productId = itemId
        vc.productIndex = sender.tag
        self.navigationController?.show(vc, sender: nil)
    }
    
    @IBAction func notificationPaySuccess(_ sender : Notification?) {
        guard let itemId = sender?.userInfo?["id"] as? String else {
            return
        }
        self.arrItems?.removeAll(where: { (item) -> Bool in
            return (item.id ?? "") == itemId
        })
        if let paymentId =  sender?.userInfo?["paymentId"] as? String {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let payDict = ["buyer_id" : userdata.id,
                           "payment_id" : paymentId,
                           "isPaid"     : true,
                           "isSold"     : false,
                           "updated"    : timestamp] as [String : Any];
            
            self.savePaymentDetails(itemId: itemId, details: payDict)
        }
        self.tblItemList.reloadData()
    }
    
    //MARK: - Custom methods
    func saveBookmarksToUserDefaults() {
        let userDict = HelperClass.fetchDataFromDefaults(with: kUserData).mutableCopy() as! NSMutableDictionary
        userDict["my_bookmarks"] = userdata.my_bookmarks
        HelperClass.saveDataToDefaults(dataObject: userDict, key: kUserData)
    }
    
    func setTableFooter(count : Int) {
        if count <= 0 {
            let lbl = UILabel()
            lbl.text = "No items in favorites"
            lbl.textAlignment = .center
            lbl.sizeToFit()
            lbl.frame.size.height = 60
            self.tblItemList.tableFooterView = lbl
        }else {
            self.tblItemList.tableFooterView = UIView.init(frame: CGRect.zero)
        }
    }
    
    func addNewItemToListWithData(itemDict : NSDictionary, itemId : String?) {
        let itemObj = ItemsDetail()
        itemObj.item_name = "\((itemDict.value(forKey: "item_name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        itemObj.price = "\((itemDict.value(forKey: "price") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        itemObj.created = Int("\((itemDict.value(forKey: "created") as? NSDictionary)?.value(forKey: "integerValue") ?? "0")")
        itemObj.subdivision = "\((itemDict.value(forKey: "subdivision") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        let brand = ((itemDict.value(forKey: "brand") as? NSDictionary)?.object(forKey: "mapValue") as? NSDictionary)?.object(forKey: "fields") as? NSDictionary
        itemObj.brand = ["id" :  "\((brand?.object(forKey: "id") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "name" :  "\((brand?.object(forKey: "name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "user" :  "\((brand?.object(forKey: "user") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"]
        
        let imagesData = ((itemDict.value(forKey: "item_images") as? NSDictionary)?.object(forKey: "arrayValue") as? NSDictionary)?.object(forKey: "values") as? [NSDictionary]
        let arrImages = imagesData?.compactMap({"\($0.value(forKey: "stringValue") ?? "")"})
        
        itemObj.item_images = arrImages
        itemObj.images_added = itemObj.item_images?.count ?? 0
        itemObj.id = itemId
        
        self.arrItems?.append(itemObj)
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
    
    func addNewItemToList(scrollToTop : Bool) {
        self.btnNewPosts.isHidden = true
        DispatchQueue.main.async {
            if self.arrNewItems != nil && self.arrNewItems?.count ?? 0 > 0 {
                if self.arrItems != nil {
                    self.arrItems?.insert(contentsOf: self.arrNewItems!, at: 0)
                }else {
                    self.arrItems = self.arrNewItems!
                }
                self.tblItemList.reloadData()
            }
            self.arrNewItems = nil
            if self.arrItems?.count ?? 0 > 1 && scrollToTop {
                self.tblItemList.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
            }
        }
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
//MARK: -
extension ItemListForSaleVC : UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemListCell
        let item = self.arrItems![indexPath.row]
        
        cell.lblItemName.text = item.item_name
        cell.lblItemBrand.text = item.brand?["name"]
        cell.lblDesciption.text = item.description
        cell.lblItemPrice.text = "$\(item.price ?? "0.00")"
        cell.lblSubDivision.text = item.subdivision ?? "N/A"
        
        let postedDate = Date(timeIntervalSince1970: TimeInterval(item.created ?? 0)/1000)
        cell.lblTimeStamp.text = postedDate.timeAgoSinceDate()
        
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
        
        cell.btnBuy?.addTarget(self, action: #selector(self.btnBuyAction(_:)), for: .touchUpInside)
        cell.btnBuy.tag = indexPath.row
        
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
        if self.tabBarController?.selectedIndex == 0 {
            let scrollViewHeight = scrollView.frame.size.height
            let scrollContentSizeHeight = scrollView.contentSize.height
            let scrollOffset = scrollView.contentOffset.y
            if ((scrollOffset + scrollViewHeight) >= (scrollContentSizeHeight - 600)) && self.isNextPage
            {
                self.isNextPage = false
                if self.isSearching {
                    self.searchItem.initialSetup()
                }else {
                    self.fetchItemList()
                }
            }else if scrollOffset <= 0 && self.arrNewItems?.count ?? 0 > 0 && self.btnNewPosts.isHidden == false {
                self.addNewItemToList(scrollToTop: false)
            }
        }
    }
    
}

//MARK: -
extension ItemListForSaleVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
        return CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
    }
    
}

extension ItemListForSaleVC : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        DispatchQueue.main.async {
            if viewController == self.navigationController && self.tabBarController?.selectedIndex == 0 {
                self.addNewItemToList(scrollToTop: true)
            }
        }
    }
    
    
}

extension ItemListForSaleVC : UISearchBarDelegate, SearchItemDelegate {
    func searchedItem(pageNo: Int, nextPage : Bool, items: [ItemsDetail]) {
        self.arrNewItems?.removeAll()
        self.btnNewPosts.isHidden = true
        self.pageNo = pageNo
        self.lastDoc = nil
        self.isNextPage = nextPage
        if self.arrItems == nil || self.pageNo == 0 || (self.pageNo == 1 && nextPage == true) {
            self.arrItems = items
            DispatchQueue.main.async {
                self.tblItemList.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
            }
        }else {
            self.arrItems?.append(contentsOf: items)
        }
        self.tblItemList.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.lastDoc = nil
        self.pageNo = 1
        self.isNextPage = true
        searchBar.resignFirstResponder()
        self.searchWithKeyword(key: searchBar.text!)
    }
    
    func searchWithKeyword(key : String) {
        self.searchItem = .init(with: self, and: key)
        self.isSearching = true
        self.searchItem.delegate = self
        self.searchItem.itemPerPage = self.itemPerPage
        self.searchItem.initialSetup()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.searchItem.searchTask?.cancel()
            self.arrItems?.removeAll()
            self.tblItemList.reloadData()
            self.pullToRefresh(searchBar)
            self.isSearching = false
            DispatchQueue.main.async {
                self.searchBar.resignFirstResponder()
            }
        }
    }
}

