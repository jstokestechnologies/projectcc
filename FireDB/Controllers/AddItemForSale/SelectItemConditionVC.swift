//
//  SelectItemConditionVC.swift
//  FireDB
//
//  Created by admin on 30/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SelectItemConditionVC: UIViewController {
    
    var delegate : ItemConditionDelegate?
    
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Item Condition"
        // Do any additional setup after loading the view.
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


extension SelectItemConditionVC : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kArrConditions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellCondition", for: indexPath)
        
        if self.selectedIndex == indexPath.row {
            cell.accessoryType = .checkmark
        }else {
            cell.accessoryType = .none
        }
        
        (cell.viewWithTag(1) as! UILabel).text = "\(kArrConditions[indexPath.row]["title"] ?? "New")"
        (cell.viewWithTag(2) as! UILabel).text = "\(kArrConditions[indexPath.row]["description"] ?? "New")"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectItemCondition(index: indexPath.row)
        self.navigationController?.popViewController(animated: true)
    }
}
