//
//  TabBarVC.swift
//  FireDB
//
//  Created by admin on 22/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class TabBarVC: UITabBarController {
    @IBOutlet weak var btnSell: UIButton!
    
    var btnWidth = CGFloat(60.0)
    var btnHeightOverTab = CGFloat(-15.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .medium)], for: .normal)
        self.view.insertSubview(self.btnSell, aboveSubview: self.tabBar)
        btnSell.layer.shadowColor = btnSell.backgroundColor?.cgColor
        btnSell.layer.masksToBounds = false
        btnSell.layer.shadowOffset = CGSize(width: 1, height: 1)
        btnSell.layer.shadowRadius = 1.5
        btnSell.layer.shadowOpacity = 0.5
        self.btnSell.addTarget(self, action: #selector(btnSellAction(_:)), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.btnSell.frame = CGRect.init(x: self.tabBar.center.x - (btnWidth/2.0), y: self.view.bounds.height - (self.tabBar.frame.height - self.btnHeightOverTab), width: btnWidth, height: btnWidth)
        self.btnSell.layer.cornerRadius = btnWidth/2.0
    }
    
    @IBAction func btnSellAction(_ sender : UIButton) {
        if self.selectedIndex != 2 {
            if (self.viewControllers?.count ?? 0) > 2, let navVC = self.viewControllers?[2] as? UINavigationController {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddSellItemVC")
                navVC.setViewControllers([vc!], animated: false)
            }
            self.selectedIndex = 2
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
