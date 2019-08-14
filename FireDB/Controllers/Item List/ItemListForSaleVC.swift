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
    var arrItems : [ItemsDetail]?
    lazy var storage = Storage.storage()
    
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchItemList()
    }
    
    func initialSetup() {
        self.btnListedItems.layer.borderColor = UIColor.lightGray.cgColor
        self.btnSavedItems.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    //MARK: - Fetch List Of Items
    func fetchItemList() {
        let itemRef = db.collection(kListedItems).order(by: "created", descending: true)
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
//MARK: - 
class ItemListCell : UITableViewCell {
    @IBOutlet weak var imgItem: UIImageView!
    @IBOutlet weak var lblItemBrand: UILabel!
    @IBOutlet weak var lblItemName: UILabel!
    @IBOutlet weak var lblItemCategory: UILabel!
    @IBOutlet weak var lblItemCondition: UILabel!
    @IBOutlet weak var lblItemPrice: UILabel!
}
