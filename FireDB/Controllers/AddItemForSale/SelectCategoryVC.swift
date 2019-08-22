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
    @IBOutlet weak var tblSubCategory: UITableView!
    
    @IBOutlet weak var const_ViewSubCat_Center_Y: NSLayoutConstraint!
    @IBOutlet weak var const_tblSubCat_bottom: NSLayoutConstraint!
    @IBOutlet weak var const_tblCat_bottom: NSLayoutConstraint!
    
    //MARK: - Variables
    var delegate : SelectCategoryProtocol?
    
    
//    var arrCategories = [[String : [String : Any]]]()
//    var arrSubCategory = [[String : Any]]()
    var dictCategory = [String : [String : Any]]()
    var dictSubCategory = [String : [String : Any]]()
    var selectedCat = [String : Any]()
    var selectedCatId = String()
    var arrSelectedCategory = Array<String>()
    
    var previousCategory : [String : [String : Any]]?
    var arrPreviousSubCat = Array<String>()
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchCategories()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Firebase Methods
    func fetchCategories() {
        progressView.showActivity()
        let itemRef = db.collection("categories")
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : [String : Any]] in
                    return [doc.documentID : doc.data()]
                })
                let dict = Dictionary.init(uniqueKeysWithValues: arr.map{ ($0.keys.first!, $0.values.first!) })
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No categories found", table: self.tlbCategory)
                }else {
                    self.tlbCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.dictCategory = dict
                self.tlbCategory.reloadData()
            }
            progressView.hideActivity()
            if self.previousCategory != nil {
                self.getPreviousSubCategory()
            }
        }
    }
    
    func fetchSubCategoryFromFireBase(_ key : String) {
        progressView.showActivity()
        let itemRef = db.collection("subcategories").whereField("cat_id", isEqualTo: key)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : [String : Any]] in
                    return [doc.documentID : doc.data()]
                })
                let dict = Dictionary.init(uniqueKeysWithValues: arr.map{ ($0.keys.first!, $0.values.first!) })
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No sub-categories found", table: self.tblSubCategory)
                }else {
                    self.tblSubCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.dictSubCategory = dict
                self.categorySetSelected(key)
                self.animateSubCategoryList()
            }
            progressView.hideActivity()
        }
    }
    
    //MARK: - Other Helper Methods
    
    func getPreviousSubCategory() {
        let key = (self.previousCategory?.keys.first) ?? "-"
        self.previousCategory = nil
        fetchSubCategoryFromFireBase(key)
    }
    
    func categorySetSelected(_ key : String) {
        self.selectedCatId = key
        self.selectedCat = dictCategory[key] ?? [String : Any]()
        self.arrSelectedCategory.removeAll()
        if self.arrPreviousSubCat.count > 0 {
            self.arrSelectedCategory.append(contentsOf: self.arrPreviousSubCat)
            self.arrPreviousSubCat.removeAll()
        }
        self.tlbCategory.reloadData()
    }
    
    func animateSubCategoryList() {
        UIView.animate(withDuration: 0.4) {
            self.const_tblSubCat_bottom.priority = .defaultHigh
            self.const_ViewSubCat_Center_Y.priority = .defaultHigh
            self.const_tblCat_bottom.priority = .defaultLow
            self.view.layoutIfNeeded()
        }
        self.tblSubCategory.reloadData()
    }
    
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
        if self.arrSelectedCategory.count > 0 {
            let dictSelectedSubCat = dictSubCategory.filter({self.arrSelectedCategory.contains($0.key)})
            self.delegate?.selectCategory([self.selectedCatId : self.selectedCat], andSubcategory: dictSelectedSubCat)
            self.navigationController?.popViewController(animated: true)
        }else {
            
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
extension SelectCategoryVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tlbCategory {
            return self.dictCategory.keys.count
        }else {
            
            return  self.dictSubCategory.keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.tlbCategory == tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellCategory", for: indexPath)
            let dictCat = Array(dictCategory.values)[indexPath.row]
            let catKey = Array(dictCategory.keys)[indexPath.row]
            let catName =  "\(dictCat["name"] ?? "-")"
            cell.textLabel?.text = catName
            cell.accessoryType = catKey == self.selectedCatId ? .checkmark : .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        
        let dictSubCat = Array(dictSubCategory.values)[indexPath.row]
        let subCatKey = Array(dictSubCategory.keys)[indexPath.row]
        let subCatName =  "\(dictSubCat["name"] ?? "-")"
        
        cell.textLabel?.text = subCatName
        let isSelected = self.arrSelectedCategory.contains(subCatKey)
        cell.accessoryType = isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tblSubCategory {
            let cell = tableView.cellForRow(at: indexPath)
            let subCatKey = Array(dictSubCategory.keys)[indexPath.row]
            if cell?.accessoryType != .checkmark {
                self.arrSelectedCategory.append(subCatKey)
            }else {
                self.arrSelectedCategory.removeAll(where: {$0 == subCatKey})
            }
            
            self.tlbCategory.reloadData()
            self.tblSubCategory.reloadData()
        }else {
            let catKey = Array(dictCategory.keys)[indexPath.row]
            if catKey != self.selectedCatId {
                self.fetchSubCategoryFromFireBase(catKey)
            }
        }
    }
    
}
