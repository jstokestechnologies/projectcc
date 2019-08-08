//
//  AddSellItemVC.swift
//  FireDB
//
//  Created by admin on 07/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class AddSellItemVC: UITableViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var collectionCondition: UICollectionView!
    @IBOutlet weak var collectionImages: UICollectionView!
    @IBOutlet weak var btnSaveDraft: UIButton!
    
    //MARK: - Properties
    
    let arrConditions = [["title":"New","description":"New with tags (NWT). Unopened packaging. Unused."],
                         ["title":"Like New","description":"NNew without tags (NWOT). No signs of usage. Looks Unused."],
                         ["title":"Good","description":"Gently used having few minor scratches. Functioning properly."]]
    
    var arrItemImages = Array<UIImage>()
    
    //MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareViews()
        // Do any additional setup after loading the view.
    }
    
    func prepareViews() {
        self.btnSaveDraft.layer.borderColor = UIColor(red:0.25, green:0.35, blue:0.82, alpha:1.0).cgColor
    }
    
    //MARK: - IBActions
    
    @IBAction func btnListAction(_ sender: Any) {
    }
    
    @IBAction func btnSaveDraftAction(_ sender: Any) {
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

//MARK: - TableView Delegate Methods
extension AddSellItemVC {
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let lbl = UILabel.init(frame: CGRect.init(x: 0.0, y: 0.0, width: 100.0, height: 22.0))
        lbl.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.0)
        lbl.text = section == 0 ? "    * REQUIRED" : " "
        lbl.textColor = UIColor(red:0.72, green:0.00, blue:0.02, alpha:1.0)
        lbl.font = UIFont.systemFont(ofSize: 15)
        
        return lbl
    }
}

//MARK: - CollectionView Delegate
extension AddSellItemVC : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionCondition {
            return self.arrConditions.count
        }
        var count = self.arrItemImages.count + 1
        count = count > maxImages ? maxImages : count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = collectionView == self.collectionCondition ? "CellCondition" : (indexPath.row == self.arrItemImages.count ? "CellAdd" : "CellImage")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        let borderColor = (collectionView == self.collectionCondition) ? UIColor.lightGray.cgColor : (UIColor.init(patternImage: UIImage.init(named: "border_dot.png")!)).cgColor
        cell.layer.borderColor = borderColor
        
        if collectionView == self.collectionCondition {
            (cell.viewWithTag(1) as! UILabel).text = "\(self.arrConditions[indexPath.row]["title"] ?? "New")"
            (cell.viewWithTag(2) as! UILabel).text = "\(self.arrConditions[indexPath.row]["description"] ?? "New")"
            return cell
        }
        
        if indexPath.row < self.arrItemImages.count {
            (cell.viewWithTag(11) as! UIImageView).image = self.arrItemImages[indexPath.row]
            
        }
        
        return cell
    }
    
    
}


