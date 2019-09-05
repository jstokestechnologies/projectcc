//
//  ItemCardTableCell.swift
//  FireDB
//
//  Created by admin on 05/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class ItemCardTableCell: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    

}

class ItemListCell : UITableViewCell {
    @IBOutlet weak var imgItem: UIImageView!
    @IBOutlet weak var lblItemBrand: UILabel!
    @IBOutlet weak var lblItemName: UILabel!
    @IBOutlet weak var lblItemCategory: UILabel!
    @IBOutlet weak var lblItemCondition: UILabel!
    @IBOutlet weak var lblItemPrice: UILabel!
    @IBOutlet weak var lblDesciption: UILabel!
    @IBOutlet weak var collectionImages: UICollectionView!
    @IBOutlet weak var pageImgPages: UIPageControl!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var btnBuy: UIButton!
    @IBOutlet weak var btnDetails: UIButton!
    
    override func draw(_ rect: CGRect) {
//        self.collectionImages.register(CollectionImagesCell.classForCoder(), forCellWithReuseIdentifier: "CellImg")
    }
    
}


class ItemImagesCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imgItem: UIImage!
}
