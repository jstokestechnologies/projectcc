//
//  FilterItemVC.swift
//  FireDB
//
//  Created by admin on 04/11/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import FirebaseStorage

class FilterItemVC: UIViewController {
    
    @IBOutlet weak var tblFilter: UITableView!
    
    var delegate : FilterDelegate?
    
    let arrTitle = ["Category", "Brand", "Subdivision"];
    var arrCategories = [[String : Any]]()
    var arrBrands = [[String : Any]]()
    var arrSelectedHeader = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchCateogry()
        self.fetchBrands()
        // Do any additional setup after loading the view.
    }
    
    func fetchCateogry() {
        self.fetchDataFromFirebase(collectionRef: "categories", completion: { (cats) in
            self.arrCategories = cats
        })
    }
    
    func fetchBrands() {
        self.fetchDataFromFirebase(collectionRef: "brands", completion: { (brands) in
            self.arrBrands = brands
        })
    }
    
    func fetchDataFromFirebase(collectionRef : String, completion : @escaping ([[String : Any]]) -> () ) {
        db.collection(collectionRef).getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                completion(arr)
            }
        }
    }
    
    @IBAction func btnHeaderAction(_ sender : UIButton) {
        if self.arrSelectedHeader.contains(sender.tag) {
            self.arrSelectedHeader.removeAll { (index) -> Bool in
                return index == sender.tag
            }
        }else {
            self.arrSelectedHeader.append(sender.tag)
        }
        self.tblFilter.reloadData()
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

extension FilterItemVC : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.arrTitle.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellFilterHeader") as! FilterViewCell
        cell.lblTitle.text = self.arrTitle[section]
        cell.backgroundColor = .white
        cell.contentView.backgroundColor = .white
        cell.btnHeader.addTarget(self, action: #selector(self.btnHeaderAction(_:)), for: .touchUpInside)
        cell.btnHeader.tag = section
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.arrSelectedHeader.contains(section) {
            switch section {
            case 0:
                return self.arrCategories.count
            case 1:
                return self.arrBrands.count
            default:
                return 0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellFilterOption", for: indexPath) as! FilterViewCell
        var dictTitle = [String : Any]()
        switch indexPath.section {
        case 0:
            dictTitle = self.arrCategories[indexPath.row]
        case 1:
            dictTitle = self.arrBrands[indexPath.row]
        default:
            print("No Data")
        }
        cell.lblTitle.text = dictTitle["name"] as? String ?? "No data"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class FilterViewCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnHeader: UIButton!
}
