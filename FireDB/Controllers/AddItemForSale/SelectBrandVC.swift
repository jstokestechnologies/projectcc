//
//  SelectBrandVC.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import FirebaseFirestore

class SelectBrandVC: UIViewController {
    
    @IBOutlet weak var tblBrands: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnAddNewBrand: UIButton!
    
    
    //MARK: - Variables
//    var arrBrand = [[String : Any]]()
//    var arrFilteredBrands = [[String : Any]]()
    var dictBrand = [String : [String : Any]]()
    var dictFilteredBrand = [String : [String : Any]]()
    var selectedIndex = -1
    
    var delegate : SelectBrandProtocol?
    var latestId = 0
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchBrand()
//        self.fetchLatestBrand()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Firebase Methods
    func fetchBrand() {
        progressView.showActivity()
        let itemRef = db.collection("brands")
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {

                let arr = documents.map({ (doc) -> [String : [String : Any]] in
                    return [doc.documentID : doc.data()]
                })
                let dict = Dictionary.init(uniqueKeysWithValues: arr.map{ ($0.keys.first!, $0.values.first!) })
                
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No brands found", table: self.tblBrands )
                }else {
                    self.tblBrands.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.dictBrand = dict
                self.dictFilteredBrand = dict
                self.tblBrands.reloadData()
            }
            progressView.hideActivity()
        }
    }
    
    func saveNewBrand(text : String) {
        progressView.showActivity()
        let brandDict = self.crateNewBrandObject(brand: text)
        
        var ref: DocumentReference? = nil
        ref = db.collection("brands").addDocument(data: brandDict) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
                self.setSelectedBrand(brand: brandDict, key: ref?.documentID ?? text)
            }
            progressView.hideActivity()
        }
    }
    
    //MARK: - Other Helper
    func showNoDataLabel(msg : String, table : UITableView) {
        let lbl = UILabel()
        lbl.text = msg
        lbl.textAlignment = .center
        lbl.sizeToFit()
        lbl.frame.size.height = 60
        table.tableFooterView = lbl
    }
    
    func crateNewBrandObject(brand : String) -> [String : Any] {
        return ["name" : brand, "user" : userdata.id]
    }
    
    func showSaveAlert(text : String) {
        let alert = UIAlertController.init(title: "", message: "Are you sure you want to add \(text) as brand?", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: { (alert) in
            self.saveNewBrand(text: text)
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: { (alert) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setSelectedBrand(brand : [String : Any], key : String) {
        var brand = brand
        brand["id"] = key
        self.delegate?.selectBrand(withName: brand)
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - IBAction
    
    @IBAction func btnAddNewBrandAction(_ sender: UIButton) {
        self.view.endEditing(true)
        let strText = self.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if strText.count > 0 {
            let arr = self.dictBrand.filter({"\($0.value["name"] ?? "-")".lowercased().contains(strText)})
            if arr.count > 0 {
                self.setSelectedBrand(brand: arr.values.first!, key: arr.keys.first!)
            }else {
                self.showSaveAlert(text: self.searchBar.text!)
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

//MARK: -
extension SelectBrandVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  self.dictFilteredBrand.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        let brand = Array(self.dictFilteredBrand.values)[indexPath.row]
        cell.textLabel?.text = "\(brand["name"] ?? "-")"
        cell.accessoryType = self.selectedIndex == indexPath.row ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        let selectedKey = Array(self.dictFilteredBrand.keys)[indexPath.row]
        DispatchQueue.main.async {
            self.setSelectedBrand(brand: self.dictFilteredBrand[selectedKey]!, key: selectedKey)
        }
    }
    
}

extension SelectBrandVC : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.selectedIndex = -1
        let strText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if strText.count > 0 {
            let filteredDict = self.dictBrand.filter({"\($0.value["name"] ?? "-")".lowercased().contains(strText)})
            self.dictFilteredBrand.removeAll()
            self.dictFilteredBrand = filteredDict
        }else {
            self.dictFilteredBrand.removeAll()
            self.dictFilteredBrand =  self.dictBrand
        }
        self.tblBrands.reloadData()
    }
}
