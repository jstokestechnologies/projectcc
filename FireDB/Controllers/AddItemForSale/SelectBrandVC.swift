//
//  SelectBrandVC.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SelectBrandVC: UIViewController {
    
    
    //MARK: - Variables
    var arrBrand = ["Leatherman Wave", "Council Tool Michigan", "Estwing Sportsman’s", "Klein Tools", "Armstrong Blacksmith"]
    var selectedIndex = -1
    
    var delegate : SelectBrandProtocol?
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    //MARK: - IBAction
    @IBAction func btnSaveAction(_ sender: Any) {
        self.delegate?.selectBrand(withName: self.arrBrand[selectedIndex])
        self.navigationController?.popViewController(animated: true)
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
        return  self.arrBrand.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellSubcategory", for: indexPath)
        cell.textLabel?.text = self.arrBrand[indexPath.row]
        
        cell.accessoryType = self.selectedIndex == indexPath.row ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        tableView.reloadData()
    }
    
}
