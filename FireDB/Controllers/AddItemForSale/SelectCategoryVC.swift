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
    
    
    var arrCategory = ["Toys" : ["Cars and Bikes", "Puzzle/assembly", "Dolls", "Educational toys", "Electronic toys", "Animals", "Construction toys"],
                       "Tools" : ["Hammers", "Pilers", "Breaker Bar", "Pry Bar", "Ratchet", "Snappers", "Screwdrivers"],
                       "Clothes" : ["Jackets", "Suits", "Sweater", "Shirts & Tops", "Waistcoats", "Tie", "T-Shirts", "Leather", "Knitwear", "Swimwear"]]
    
    var arrCategories = [[String : [String : Any]]]()
    var arrSubCategory = [[String : Any]]()
    var selectedCatIndex = -1
    var arrSelectedCategory = Array<String>()
    
    var previousCategory = String()
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
        var previousIndex = -1
        let itemRef = db.collection("categories")
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                var arr = Array<[String : [String : Any]]>()
                for i in 0..<documents.count {
                    let doc = documents[i]
                    arr.append([doc.documentID : doc.data()])
                    if "\(doc.data()["name"] ?? "-")" == self.previousCategory && self.previousCategory != "" {
                        self.previousCategory = ""
                        previousIndex = i
                    }
                }
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No categories found", table: self.tlbCategory)
                }else {
                    self.tlbCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.arrCategories = arr
                self.tlbCategory.reloadData()
            }
            progressView.hideActivity()
            if previousIndex >= 0 {
                self.fetchSubCategories(index: previousIndex)
            }
        }
    }
    
    func fetchSubCategories(index : Int) {
        progressView.showActivity()
        let key = Array(self.arrCategories[index].keys)[0]
        let itemRef = db.collection("subcategories").whereField("cat_id", isEqualTo: key)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                var arr = Array<[String : Any]>()
                for doc in documents {
                    arr.append(doc.data())
                }
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No sub-categories found", table: self.tblSubCategory)
                }else {
                    self.tblSubCategory.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.arrSubCategory = arr
                self.categorySetSelected(index)
                self.animateSubCategoryList()
            }
            progressView.hideActivity()
        }
    }
    
    func findPreviousSelectedCategory() {
        
    }
    
    func categorySetSelected(_ index : Int) {
        self.selectedCatIndex = index
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
            let arr = Array(self.arrCategories[self.selectedCatIndex].values)
            let cat = "\((arr[0])["name"] ?? "-")"
            self.delegate?.selectCategory(cat, andSubcategory: self.arrSelectedCategory)
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
            return self.arrCategories.count
        }else {
            
            return  self.arrSubCategory.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.tlbCategory == tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellCategory", for: indexPath)
            let arr = Array(self.arrCategories[indexPath.row].values)
            cell.textLabel?.text = "\((arr[0])["name"] ?? "-")"
            cell.accessoryType = indexPath.row == self.selectedCatIndex ? .checkmark : .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        cell.textLabel?.text = "\((self.arrSubCategory[indexPath.row])["name"] ?? "-")"
        let isSelected = self.arrSelectedCategory.contains(cell.textLabel?.text ?? "")
        cell.accessoryType = isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tblSubCategory {
            let cell = tableView.cellForRow(at: indexPath)
            let subCat = "\((self.arrSubCategory[indexPath.row])["name"] ?? "-")"
            if cell?.accessoryType != .checkmark {
                self.arrSelectedCategory.append(subCat)
            }else {
                self.arrSelectedCategory.removeAll(where: {$0 == subCat})
            }
            
            self.tlbCategory.reloadData()
            self.tblSubCategory.reloadData()
        }else {
            if indexPath.row != self.selectedCatIndex {
                self.fetchSubCategories(index: indexPath.row)
            }
        }
    }
    
}
