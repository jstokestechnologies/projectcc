//
//  SoldItemsListVC.swift
//  FireDB
//
//  Created by admin on 30/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

class SoldItemsListVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var tblItemList: UITableView!
    
    @IBOutlet weak var btnListedItems: UIButton!
    @IBOutlet weak var btnSavedItems: UIButton!
    
    
    //MARK: - Variables
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Archived items"
        progressView.showActivity()
        self.fetchItemList()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Fetch List Of Items
    func fetchItemList() {
        let itemRef = db.collection(kListedItems).whereField("isArchived", isEqualTo: true).whereField("user_id", isEqualTo: userdata.id).order(by: "updated", descending: true)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                var arr = Array<[String : Any]>()
                for doc in documents {
                    arr.append(doc.data())
                }
                if arr.count <= 0 {
                    let lbl = UILabel()
                    lbl.text = "No items found"
                    lbl.textAlignment = .center
                    lbl.sizeToFit()
                    lbl.frame.size.height = 60
                    self.tblItemList.tableFooterView = lbl
                }else {
                    self.tblItemList.tableFooterView = UIView.init(frame: CGRect.zero)
                }
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
}


//MARK: -
extension SoldItemsListVC : UITableViewDelegate, UITableViewDataSource {
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
        cell.collectionImages.allowsSelection = false
        cell.collectionImages.reloadData()
        
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
extension SoldItemsListVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let item = self.arrItems![collectionView.tag]
        return item.item_images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellItemImage, for: indexPath)
        
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
