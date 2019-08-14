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
        var child = ""
        switch self.listType {
        case .listedItems:
            child = kListedItems
        default:
            child = kSavedItems
        }
        
        let itemRef = db.collection(child).whereField("user_id", isEqualTo: userdata.id)
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
                    self.tblItemList.reloadData()
                }
                catch {
                    print(error.localizedDescription)
                }
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

extension MyListedItemsVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemListCell
        let item = self.arrItems![indexPath.row]
        
        cell.lblItemName.text = item.item_name
        cell.lblItemBrand.text = item.brand
        if (item.sub_category?.count ?? 0) > 0 {
            cell.lblItemCategory.text = "\(item.category ?? "N/A") -> \(item.sub_category?.joined(separator: ", ") ?? "N/A")"
        }else {
            cell.lblItemCategory.text = item.category ?? "N/A"
        }
        cell.lblItemCondition.text = "Condition : \(item.condition ?? "")"
        cell.lblItemPrice.text = "Price : $\(item.price ?? "0.00")"
        
        let storageRef = storage.reference(withPath: item.item_images![0])
        cell.imgItem.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        
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
}


