//
//  SelectCategoryVC.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SelectCategoryVC: UIViewController {
    @IBOutlet weak var tlbCategory: UITableView!
    @IBOutlet weak var tblSubCategory: UITableView!
    
    var delegate : SelectCategoryProtocol?
    
    
    let arrCategory = ["Toys" : ["Cars and Bikes", "Puzzle/assembly", "Dolls", "Educational toys", "Electronic toys", "Animals", "Construction toys"],
                       "Tools" : ["Hammers", "Pilers", "Breaker Bar", "Pry Bar", "Ratchet", "Snappers", "Screwdrivers"],
                       "Clothes" : ["Jackets", "Suits", "Sweater", "Shirts & Tops", "Waistcoats", "Tie", "T-Shirts", "Leather", "Knitwear", "Swimwear"]]
    
    var arrSubCategory = Array<String>()
    var selectedCatIndex = -1
    var arrSelectedCategory = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnSaveAction(_ sender: Any) {
        if self.arrSelectedCategory.count > 0 {
            self.delegate?.selectCategory(Array(self.arrCategory.keys)[self.selectedCatIndex], andSubcategory: self.arrSelectedCategory)
            self.dismiss(animated: true, completion: nil)
        }else {
            
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

extension SelectCategoryVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tlbCategory {
            return self.arrCategory.count
        }else {
            
            return  self.arrSubCategory.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.tlbCategory == tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellCategory", for: indexPath)
            cell.textLabel?.text = Array(self.arrCategory.keys)[indexPath.row]
            cell.accessoryType = indexPath.row == self.selectedCatIndex ? .checkmark : .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        cell.textLabel?.text = self.arrSubCategory[indexPath.row]
        let isSelected = self.arrSelectedCategory.contains(cell.textLabel?.text ?? "")
        cell.accessoryType = isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tblSubCategory {
            let cell = tableView.cellForRow(at: indexPath)
            
            if cell?.accessoryType != .checkmark {
                self.arrSelectedCategory.append(self.arrSubCategory[indexPath.row])
            }else {
                self.arrSelectedCategory.removeAll(where: {$0 == self.arrSubCategory[indexPath.row]})
            }
            
            self.tlbCategory.reloadData()
            self.tblSubCategory.reloadData()
        }else {
            if indexPath.row != self.selectedCatIndex {
                self.selectedCatIndex = indexPath.row
                self.arrSelectedCategory.removeAll()
                self.arrSubCategory = self.arrCategory[(Array(self.arrCategory.keys))[indexPath.row]] ?? [String]()
                
                self.tlbCategory.reloadData()
                self.tblSubCategory.reloadData()
            }
        }
    }
    
}
