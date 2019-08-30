//
//  MyListedItemsVC.swift
//  FireDB
//
//  Created by admin on 13/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

class MyListedItemsVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var tblItemList: UITableView!
    
    @IBOutlet weak var btnListedItems: UIButton!
    @IBOutlet weak var btnSavedItems: UIButton!
    
    
    //MARK: - Variables
    enum ItemsListType {
        case savedItems
        case listedItems
    }
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    var listType = ItemsListType.listedItems
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        switch self.listType {
        case .listedItems:
            self.title = "My Listed Items"
        default:
            self.title = "My Saved Items"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchItemList()
    }
    
    //MARK: - Fetch List Of Items
    func fetchItemList() {
        progressView.showActivity()
        
        let itemRef = db.collection(kListedItems).whereField("isPosted", isEqualTo: self.listType == .listedItems).whereField("isDeleted", isEqualTo: false).whereField("user_id", isEqualTo: userdata.id).order(by: "updated", descending: true)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                
                do {
                    let jsonData  = try? JSONSerialization.data(withJSONObject: arr, options:.prettyPrinted)
                    let jsonDecoder = JSONDecoder()
                    //                                    var userdata = UserData.sharedInstance
                    self.arrItems = try jsonDecoder.decode([ItemsDetail].self, from: jsonData!)
                    self.tblItemList.reloadData()
                }
                catch {
                    print(error.localizedDescription)
                }
                self.setNoDataLabel()
            }
            progressView.hideActivity()
        }
    }
    
    func postDeleteSelectedItem(index : Int, isPost : Bool) {
        if let itemid = self.arrItems?[index].id {
            let key = isPost ? "isPosted" : "isDeleted"
            db.collection(kListedItems).document(itemid).updateData([key : true]) { (err) in
                if (err != nil) {
                    HelperClass.showAlert(msg: err?.localizedDescription ?? "Failed to update changes", isBack: false, vc: self)
                }else {
                    self.fetchItemList()
                }
            }
        }
    }
    
    
    @IBAction func btnMoreAction(_ sender: UIButton) {
        let actionSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction.init(title: "Edit", style: .default, handler: { (alert) in
            self.showEditController(forItem: sender.tag)
        }))
        
        actionSheet.addAction(UIAlertAction.init(title: "Delete", style: .default, handler: { (alert) in
            self.showDeleteMessageAlert(forItem: sender.tag, isPost: false)
        }))
        
        if self.listType == .savedItems {
            actionSheet.addAction(UIAlertAction.init(title: "Post", style: .default, handler: { (alert) in
                self.showDeleteMessageAlert(forItem: sender.tag, isPost: true)
            }))
        }
        
        actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (alert) in
            
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func showEditController(forItem index : Int) {
        if let item = self.arrItems?[index], item.id != nil {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddSellItemVC") as! AddSellItemVC
            vc.itemData = item
            vc.isEditingItem = true
            vc.itemId = item.id!
            switch self.listType {
            case .listedItems:
                vc.itemType = .listedItems
            default:
                vc.itemType = .savedItems
            }
            self.navigationController?.show(vc, sender: nil)
        }
    }
    
    func showDeleteMessageAlert(forItem index : Int, isPost : Bool) {
        var strMsg = ""
        if isPost {
            strMsg = "Are you sure you want to post this item for sale?"
        }else {
            strMsg = "Are you sure you want to delete this item?"
        }
        let alert = UIAlertController.init(title: nil, message: strMsg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            self.postDeleteSelectedItem(index: index, isPost: isPost)
        }))
        
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
            
        }))
        self.present(alert, animated: true, completion: nil)
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
extension MyListedItemsVC : UITableViewDelegate, UITableViewDataSource {
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
        cell.pageImgPages.numberOfPages = item.item_images?.count ?? 0
        cell.pageImgPages.isHidden = (item.item_images?.count ?? 0) <= 1
        cell.collectionImages.tag = indexPath.row
        cell.collectionImages.reloadData()
        
        cell.btnMore.tag = indexPath.row
        cell.btnMore.addTarget(self, action: #selector(self.btnMoreAction(_:)), for: .touchUpInside)
        
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
extension MyListedItemsVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let item = self.arrItems![collectionView.tag]
        return item.item_images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellImg", for: indexPath)
        
        let item = self.arrItems![collectionView.tag]
        let storageRef = storage.reference(withPath: item.item_images![indexPath.row])
        (cell.viewWithTag(11) as! UIImageView).image = UIImage.init(named: "no-image")
        (cell.viewWithTag(11) as! UIImageView).sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width, height: collectionView.frame.size.height)
    }
    
}


