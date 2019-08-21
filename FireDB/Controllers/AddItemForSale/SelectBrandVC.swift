//
//  SelectBrandVC.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SelectBrandVC: UIViewController {
    
    @IBOutlet weak var tblBrands: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnAddNewBrand: UIButton!
    
    
    //MARK: - Variables
    var arrBrand = [[String : Any]]()
    var arrFilteredBrands = [[String : Any]]()
    var selectedIndex = -1
    
    var delegate : SelectBrandProtocol?
    var latestId = 0
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchBrand()
        self.fetchLatestBrand()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Firebase Methods
    func fetchBrand() {
        progressView.showActivity()
        let itemRef = db.collection("brands")
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                var arr = Array<[String : Any]>()
                for doc in documents {
                    arr.append(doc.data())
                }
                if arr.count <= 0 {
                    self.showNoDataLabel(msg: "No sub-categories found", table: self.tblBrands )
                }else {
                    self.tblBrands.tableFooterView = UIView.init(frame: CGRect.zero)
                }
                self.arrBrand = arr
                self.arrFilteredBrands = arr
                self.tblBrands.reloadData()
            }
            progressView.hideActivity()
//            self.getLatestBrandId()
        }
    }
    
    func fetchLatestBrand() {
        let itemRef = db.collection("brands").order(by: "id", descending: true).limit(to: 1)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                if let latestBrand = documents.first?.data() {
                    self.latestId = Int("\(latestBrand["id"] ?? "0")") ?? 0
                }
            }
        }
    }
    
    func saveNewBrand(text : String) {
        progressView.showActivity()
        let brandDict = self.crateNewBrandObject(brand: text)
        db.collection("brands").document("\(brandDict["id"] ?? (self.latestId + 1))").setData(brandDict, completion: { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.setSelectedBrand(brand: brandDict)
            } else {
                print("Document added with ID:\n\n\n\n\n ")
            }
            progressView.hideActivity()
        })
    }
    
    //MARK: - Other Helper
    func getLatestBrandId() {
        let arr = self.arrBrand.sorted(by: {Int("\($0["id"] ?? "0")") ?? 0 > (Int("\($1["id"] ?? "0")") ?? 0)})
        if arr.count > 0 {
            self.latestId = Int("\(arr.first!["id"] ?? "0")") ?? 0
        }
    }
    
    func showNoDataLabel(msg : String, table : UITableView) {
        let lbl = UILabel()
        lbl.text = msg
        lbl.textAlignment = .center
        lbl.sizeToFit()
        lbl.frame.size.height = 60
        table.tableFooterView = lbl
    }
    
    func crateNewBrandObject(brand : String) -> [String : Any] {
        return ["name" : brand, "id" : self.latestId + 1, "user" : userdata.id]
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
    
    func setSelectedBrand(brand : [String : Any]) {
        self.delegate?.selectBrand(withName: brand)
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - IBAction
    @IBAction func btnSaveAction(_ sender: Any) {
        if self.selectedIndex >= 0 {
            self.setSelectedBrand(brand: self.arrFilteredBrands[self.selectedIndex])
        }else {
            HelperClass.showAlert(msg: "Please select a brand", isBack: false, vc: self)
        }
    }
    
    @IBAction func btnAddNewBrandAction(_ sender: UIButton) {
        self.view.endEditing(true)
        let strText = self.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if strText.count > 0 {
            let arr = self.arrBrand.filter({"\($0["name"] ?? "-")".lowercased().contains(strText)})
            if arr.count > 0 {
                self.setSelectedBrand(brand: arr.first!)
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
        return  self.arrFilteredBrands.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        cell.textLabel?.text = "\((self.arrFilteredBrands[indexPath.row])["name"] ?? "-")"
        cell.accessoryType = self.selectedIndex == indexPath.row ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.setSelectedBrand(brand: self.arrFilteredBrands[indexPath.row])
    }
    
}

extension SelectBrandVC : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.selectedIndex = -1
        let strText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if strText.count > 0 {
            let arr = self.arrBrand.filter({"\($0["name"] ?? "-")".lowercased().contains(strText)})
            self.arrFilteredBrands.removeAll()
            self.arrFilteredBrands.append(contentsOf: arr)
        }else {
            self.arrFilteredBrands.removeAll()
            self.arrFilteredBrands.append(contentsOf: self.arrBrand)
        }
        self.tblBrands.reloadData()
    }
}
