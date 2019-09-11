//
//  CropImageVC.swift
//  FireDB
//
//  Created by admin on 10/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class CropImageVC: UIViewController {
    
    @IBOutlet weak var imgItem: UIImageView!
    @IBOutlet weak var cropView: UIView!
    
    @IBOutlet weak var cropButtonsView: UIView!
    
    var imageToCrop = UIImage()
    var editView = LyEditImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imgItem.image = imageToCrop
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnRetakeAction(_ sender : UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSellAction(_ sender : UIButton) {
        let parentVC = self.presentingViewController
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: "ImageSelected"), object: nil, userInfo: ["image" : self.imageToCrop])
        self.dismiss(animated: false) {
            parentVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func btnCropImageAction(_ sender : UIButton) {
        DispatchQueue.main.async {
            self.cropView.isHidden = true
            self.cropButtonsView.isHidden = false
            
            self.editView = LyEditImageView.init()
            self.editView = LyEditImageView(frame: self.view.bounds)
            self.editView.initWithImage(image: self.imageToCrop)
            
            self.view.addSubview(self.editView)
            self.view.bringSubviewToFront(self.cropButtonsView)
        }
    }
    
    @IBAction func btnSetCroppedImageAction(_ sender : UIButton) {
        self.imageToCrop = editView.getCroppedImage()
        self.imgItem.image = self.imageToCrop
        
        self.btnCancelCropAction(sender)
    }
    
    @IBAction func btnCancelCropAction(_ sender : UIButton) {
        editView.removeFromSuperview()
        self.cropButtonsView.isHidden = true
        self.cropView.isHidden = false
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
