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
    
    @IBOutlet weak var tblItemList: UITableView!
    
    
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchItemList()
        // Do any additional setup after loading the view.
    }
    
    func fetchItemList() {
        let itemRef = db.collection(kListedItems)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                var arr = Array<[String : Any]>()
                for doc in documents {
                    arr.append(doc.data())
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
     
    }
    */

}

extension ItemListForSaleVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemListCell
        let item = self.arrItems![indexPath.row]
        let category = item.category?.first ?? "N/A"
        item.category?.removeFirst()
        cell.lblItemName.text = item.name
        cell.lblItemBrand.text = item.brand
        if (item.category?.count ?? 0) > 0 {
            cell.lblItemCategory.text = "\(category) -> \(item.category?.joined(separator: ", ") ?? "N/A")"
        }else {
            cell.lblItemCategory.text = category
        }
        cell.lblItemCondition.text = "Condition : \(item.condition ?? "")"
        cell.lblItemPrice.text = "Price : $\(item.price ?? "0.00")"
        
        let storageRef = storage.reference(withPath: item.item_images![0])
        cell.imgItem.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 148.00
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

class ItemListCell : UITableViewCell {
    @IBOutlet weak var imgItem: UIImageView!
    @IBOutlet weak var lblItemBrand: UILabel!
    @IBOutlet weak var lblItemName: UILabel!
    @IBOutlet weak var lblItemCategory: UILabel!
    @IBOutlet weak var lblItemCondition: UILabel!
    @IBOutlet weak var lblItemPrice: UILabel!
}
