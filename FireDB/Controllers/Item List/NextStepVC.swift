//
//  NextStepVC.swift
//  FireDB
//
//  Created by admin on 30/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class NextStepVC: UIViewController {
    
    var delegate : NextStepDelegate?
    let itemIndex = Int()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextStepAction(_ sender : UIButton) {
        self.dismiss(animated: true, completion: nil)
        self.delegate?.didRemoveNextStepPopup(withIndex: self.itemIndex)
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
