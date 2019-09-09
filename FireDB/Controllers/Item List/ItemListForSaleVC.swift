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
    
    
    //MARK: - Variables
    var refreshControl = UIRefreshControl()
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    var bookmarkPage = 0
    var isLoadingList = true
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        if self.tabBarController?.selectedIndex == 0 {
            progressView.showActivity()
            self.fetchItemList()
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
            self.arrItems = [ItemsDetail]()
            self.arrItems?.removeAll()
            self.tblItemList.reloadData()
            self.bookmarkPage = 0
            self.isLoadingList = true
            progressView.showActivity()
            self.fetchBookmarkedItems()
        }
    }
    
    func initialSetup() {
        self.tabBarController?.delegate = self
        self.btnListedItems.layer.borderColor = UIColor.lightGray.cgColor
        self.btnSavedItems.layer.borderColor = UIColor.lightGray.cgColor
        if userdata.my_bookmarks == nil {
            userdata.my_bookmarks = [String]()
        }
        self.refreshControl.addTarget(self, action: #selector(self.refreshControllAction(_:)), for: .valueChanged)
        self.tblItemList.refreshControl = self.refreshControl
    }
    
    //MARK: - Firebase Methods
    func fetchBookmarkedItems() {
        let concurrentQueue = DispatchQueue(label: "com.queue.Concurrent", attributes: .concurrent)
        let group = DispatchGroup()
        
        // Fetch item data
        if (userdata.my_bookmarks?.count ?? 0) > (self.bookmarkPage * 2) {
            var arrBookmarks = userdata.my_bookmarks
            if arrBookmarks?.count ?? 0 <= self.bookmarkPage * 2 {
                return
            }
            arrBookmarks?.removeFirst(self.bookmarkPage * 2)
            let remainingItems = arrBookmarks?.count ?? 0
            if remainingItems > 2 {
                arrBookmarks?.removeLast(remainingItems - 2)
            }
            for itemId in arrBookmarks! {
                group.enter()
                concurrentQueue.async {
                    let itemRef = db.collection(kListedItems).document("/\(itemId)")
                    itemRef.getDocument { (doc, err) in
                        if let data = doc?.data() {
                            do {
                                let jsonData  = try? JSONSerialization.data(withJSONObject: data, options:.prettyPrinted)
                                let jsonDecoder = JSONDecoder()
                                let itemData = try jsonDecoder.decode(ItemsDetail.self, from: jsonData!)
                                itemData.id = itemId
                                self.arrItems?.append(itemData)
                            }
                            catch {
                                print(error.localizedDescription)
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        
        // Notify when done fetching bookmarked items
        group.notify(queue: DispatchQueue.main) {
            DispatchQueue.main.async {
                self.setTableFooter(count: self.arrItems?.count ?? 0)
                self.tblItemList.reloadData()
                progressView.hideActivity()
                self.isLoadingList = false
            }
        }
    }
    
    func fetchItemList() {
        let itemRef = db.collection(kListedItems).whereField("isPosted", isEqualTo: true).whereField("isArchived", isEqualTo: false).order(by: "created", descending: true)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                self.setTableFooter(count: arr.count)
                do {
                    let jsonData  = try? JSONSerialization.data(withJSONObject: arr, options:.prettyPrinted)
                    let jsonDecoder = JSONDecoder()
                    //                                    var userdata = UserData.sharedInstance
                    self.arrItems = try jsonDecoder.decode([ItemsDetail].self, from: jsonData!)
                    DispatchQueue.main.async {
                        self.tblItemList.reloadData()
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            progressView.hideActivity()
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
    
    //MARK: - Button IBAction
    @IBAction func btnLogoutAction(_ sender: Any) {
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
    
    @IBAction func btnAddItemForSaleAction(_ sender: Any) {
        let vc = (self.storyboard?.instantiateViewController(withIdentifier: "AddSellItemVC"))!
        let navVC = UINavigationController.init(rootViewController: vc)
        navVC.navigationBar.tintColor = .darkGray
        self.present(navVC, animated: true, completion: nil)
    }
    
    @IBAction func btnShowMyListedItemsAction(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
        vc.listType = .listedItems
        self.navigationController?.show(vc, sender: self)
    }
    
    @IBAction func btnShowMySavedItemsAction(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyListedItemsVC") as! MyListedItemsVC
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
    
    @IBAction func refreshControllAction(_ sender: Any) {
        progressView.showActivity()
        if self.tabBarController?.selectedIndex == 0 {
            self.fetchItemList()
        }else {
            self.arrItems = [ItemsDetail]()
            self.arrItems?.removeAll()
            self.isLoadingList = true
            self.bookmarkPage = 0
            self.tblItemList.reloadData()
            self.fetchBookmarkedItems()
        }
        self.refreshControl.endRefreshing()
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
            lbl.text = "No items found"
            lbl.textAlignment = .center
            lbl.sizeToFit()
            lbl.frame.size.height = 60
            self.tblItemList.tableFooterView = lbl
        }else {
            self.tblItemList.tableFooterView = UIView.init(frame: CGRect.zero)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height ) && !isLoadingList) && (userdata.my_bookmarks?.count ?? 0) > (self.arrItems?.count ?? 0) && self.tabBarController?.selectedIndex == 3 {
            self.isLoadingList = true
            self.bookmarkPage = self.bookmarkPage + 1
            self.fetchBookmarkedItems()
//            self.tblItemList.reloadData()
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
extension ItemListForSaleVC : UITableViewDelegate, UITableViewDataSource {
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
        return 148.00
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            if let cellView = scrollView.superview?.superview {
                if cellView.isKind(of: ItemListCell.classForCoder()) && scrollView.isKind(of: UICollectionView.classForCoder()) {
                    let cell = cellView as! ItemListCell
                    let index = cell.collectionImages.indexPathsForVisibleItems
                    cell.pageImgPages.currentPage = index[0].row
                }
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
        return CGSize(width: self.view.frame.size.width, height: collectionView.frame.size.height)
    }
    
}

extension ItemListForSaleVC : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if self.tabBarController?.selectedIndex == 0  {
            self.tblItemList.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: 50, height: 50), animated: true)
            self.fetchItemList()
        }
    }
}


