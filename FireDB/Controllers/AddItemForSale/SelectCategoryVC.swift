//
//  SelectCategoryVC.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SelectCategoryVC: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var tlbCategory: UITableView!
    
    //MARK: - Variables
    var delegate : SelectCategoryProtocol?
    
//    var dictCategory = [String : [String : Any]]()
    var arrCategory = [[String : Any]]()
    var parentCategories = [String : [String : Any]]()
    var parentCatIDs : [String]?
    var collectionName = String()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.parentCatIDs != nil {
            self.fetchSubCategories()
            self.title = (self.parentCategories[self.parentCatIDs?.last ?? ""])?["name"] as? String ?? "Subcategories"
        }else {
            self.fetchCategories()
            self.title = "Category"
        }
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Firebase Methods
    func fetchCategories() {
        progressView.showActivity()
        let itemRef = db.collection(self.collectionName).order(by: "name", descending: false)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict = doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
//                let dict = Dictionary.init(uniqueKeysWithValues: arr.map{ ($0.keys.first!, $0.values.first!) })
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No categories found", table: self.tlbCategory)
                }else {
                    self.tlbCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.arrCategory = arr
//                self.dictCategory = dict
                self.tlbCategory.reloadData()
            }
            progressView.hideActivity()
        }
    }
    
    func fetchSubCategories() {
        progressView.showActivity()
        let itemRef = db.collection(self.collectionName).order(by: "name", descending: false).whereField("cat_id", isEqualTo: (self.parentCatIDs?.last ?? ""))
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict = doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
//                let dict = Dictionary.init(uniqueKeysWithValues: arr.map{ ($0.keys.first!, $0.values.first!) })
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No sub-categories found", table: self.tlbCategory)
                }else {
                    self.tlbCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.arrCategory = arr
//                self.dictCategory = dict
                self.tlbCategory.reloadData()
            }
            progressView.hideActivity()
        }
    }
    
    //MARK: - Other Helper Methods
    func showNoDataLabel(msg : String, table : UITableView) {
        let lbl = UILabel()
        lbl.text = msg
        lbl.textAlignment = .center
        lbl.sizeToFit()
        lbl.frame.size.height = 60
        table.tableFooterView = lbl
    }
    
    //MARK: - IBAction
    @IBAction func btnSaveAction(_ sender: Any) {
        
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
extension SelectCategoryVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrCategory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellCategory", for: indexPath)
        let dictCat = arrCategory[indexPath.row]
        let catName =  "\(dictCat["name"] ?? "-")"
        cell.textLabel?.text = catName
        cell.accessoryType = self.parentCatIDs == nil ? .disclosureIndicator : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let catKey = (self.arrCategory[indexPath.row])["id"] as? String ?? ""
        var category = self.arrCategory[indexPath.row]
        category.removeValue(forKey: "id")
        if (category["is_subcategory"] as? Bool ?? false) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SelectCategoryVC") as! SelectCategoryVC
            category.removeValue(forKey: "is_subcategory")
            vc.collectionName = "subcategories"
            if self.parentCatIDs != nil {
                vc.parentCatIDs = self.parentCatIDs
                vc.parentCatIDs?.append(catKey)
            }else {
                vc.parentCatIDs = [catKey]
            }
            vc.parentCategories[catKey] = category
            self.navigationController?.show(vc, sender: self)
        }else {
            if self.parentCatIDs != nil {
                self.parentCatIDs?.append(catKey)
            }else {
                self.parentCatIDs = [catKey]
            }
            self.parentCategories[catKey] = category
            
            let userInfo = ["cat_ids"   : self.parentCatIDs!,
                            "categories": self.parentCategories] as [String : Any]
            
            NotificationCenter.default.post(name: NSNotification.Name.init(kNotification_Category), object: nil, userInfo: userInfo)
            if let vcs = self.navigationController?.viewControllers {
                for vc in vcs {
                    if vc.isKind(of: AddSellItemVC.classForCoder()) {
                        self.navigationController?.popToViewController(vc, animated: true)
                        return
                    }
                }
                if self.parentCatIDs != nil && vcs.count >= (self.parentCatIDs?.count ?? 0) {
                    var count = vcs.count - (self.parentCatIDs?.count ?? 0)
                    count = count < 0 ? 0 : count
                    let vc = vcs[count - 1]
                    self.navigationController?.popToViewController(vc, animated: true)
                }else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
}
extension Dictionary where Value:Comparable {
    var sortedByValue:[(Key,Value)] {return Array(self).sorted{$0.1 < $1.1}}
}
