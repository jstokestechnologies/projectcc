//
//  PendingDispatchVC.swift
//  FireDB
//
//  Created by admin on 23/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

class PendingDispatchVC: UIViewController {
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
        self.title = "Paid Orders"
        self.tblItemList.register(UINib(nibName: "ItemCardTableCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchItemList()
    }
    
    //MARK: - Fetch List Of Items
    func fetchItemList() {
        progressView.showActivity()
        
        let itemRef = db.collection(kListedItems).whereField("isPaid", isEqualTo: true).whereField("isArchived", isEqualTo: false).whereField("isSold", isEqualTo: false).whereField("user_id", isEqualTo: userdata.id).order(by: "updated", descending: true)
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
    
    
    func showDeleteMessageAlert(forItem index : Int, isPost : Bool) {
        let strMsg = "Are you sure you want to delete this item. You won't be able to recover it again."
        
        let alert = UIAlertController.init(title: nil, message: strMsg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            
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
    
    @IBAction func btnDispatchAction(_ sender : UIButton) {
        let item = self.arrItems?[sender.tag]
        if let payId = item?.payment_id, let price = item?.price  {
            let amount = price
            self.capturePaymentIntent(withIntentId: payId, amount: Int(amount * 100), index: sender.tag, itemId: item?.id ?? "")
            progressView.showActivity()
        }
    }
    
    func capturePaymentIntent(withIntentId intentId: String, amount : Int, index : Int, itemId : String) {
        let url = URL.init(string: (kBaseURL + URLCapturePayment))
        var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: false)! //cus_G0wB7Ps2IeYt1h
        urlComponents.queryItems = [URLQueryItem(name: "payment_id", value: intentId), URLQueryItem(name: "amount", value: "\(amount)")]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data, error == nil {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    print(jsonData)
                }catch {
                    print(error.localizedDescription)
                }
                self.arrItems?.remove(at: index)
                DispatchQueue.main.async {
                    self.tblItemList.reloadData()
                }
                
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                let payDict = ["isSold"     : true,
                               "updated"    : timestamp] as [String : Any];
                self.savePaymentDetails(itemId: itemId, details: payDict)
            }else {
                print(error?.localizedDescription ?? "Unknown error")
            }
            DispatchQueue.main.async {
                progressView.hideActivity()
            }
        })
        task.resume()
    }
    
    func savePaymentDetails(itemId : String, details : [String : Any]) {
        db.collection(kListedItems).document(itemId).setData(details, merge: true)
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
extension PendingDispatchVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemListCell
        let item = self.arrItems![indexPath.row]
        
        cell.lblItemName.text = item.item_name
        cell.lblItemBrand.text = item.brand?["name"]
        cell.lblDesciption.text = item.description
        cell.lblItemPrice.text = "$\(item.price ?? 0.0)"
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
        
        if userdata.my_bookmarks?.contains(item.id ?? " ") ?? false {
            cell.btnBookmark.setImage(UIImage.init(named: "bookmark_filled"), for: .normal)
        }else {
            cell.btnBookmark.setImage(UIImage.init(named: "bookmark_outline"), for: .normal)
        }
        
        cell.btnBuy.setTitle("Dispatched/Delivered", for: .normal)
        cell.btnBuy?.addTarget(self, action: #selector(self.btnDispatchAction(_:)), for: .touchUpInside)
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
extension PendingDispatchVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
