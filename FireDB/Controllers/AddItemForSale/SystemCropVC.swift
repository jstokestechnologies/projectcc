//
//  SystemCropVC.swift
//  FireDB
//
//  Created by admin on 17/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class SystemCropVC: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrolView: UIScrollView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var const_image_height: NSLayoutConstraint!
    @IBOutlet weak var const_scroll_height: NSLayoutConstraint!
    
    @IBOutlet weak var viewMax: UIView!
    
    var imgToCrop = UIImage()
    var isFirstVC = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrolView.maximumZoomScale = 2.0
        self.scrolView.minimumZoomScale = 1.0
//        self.scrolView.bouncesZoom = false
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.scrolView.layer.borderWidth = 1
            self.scrolView.layer.borderColor = UIColor.white.cgColor
            
            var height = self.imgToCrop.size.height/self.imgToCrop.size.width * self.view.frame.width
            height = height > self.viewMax.frame.size.height ? self.viewMax.frame.size.height : height
            
            self.const_image_height.constant = height
//            self.const_scroll_height.constant = height
            self.view.layoutSubviews()
            self.scrolView.contentSize = CGSize.init(width: self.view.frame.size.width, height: height)
            if self.const_scroll_height.constant < self.const_image_height.constant {
                let y = (self.const_image_height.constant - self.const_scroll_height.constant)/2
                self.scrolView.scrollRectToVisible(CGRect.init(x: 0, y: y, width: self.const_scroll_height.constant, height: self.const_scroll_height.constant), animated: false)
            }
            self.imgView.image = self.imgToCrop
        }
    }
    
    @IBAction func btnRetakeAction(_ sender: Any) {
//        if (self.navigationController != nil) {
//            self.navigationController?.popViewController(animated: true)
//        }else {
            self.dismiss(animated: false, completion: nil)
//        }
    }
    
    @IBAction func btnCropAction(_ sender: Any) {
        let cropX = self.scrolView.contentOffset.x
        let cropY = self.scrolView.contentOffset.y
        let width = self.scrolView.frame.width
        let height = self.scrolView.frame.height
        let image = self.imgToCrop.resizeImage(targetSize: self.imgView.bounds.size)
        if let img = image.sd_croppedImage(with: CGRect.init(x: cropX, y: cropY, width: width, height: height)) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CropImageVC") as! CropImageVC
            vc.imageToCrop = img
            if let navVC = self.presentingViewController as? UINavigationController, self.isFirstVC {
                self.dismiss(animated: false) {
                    navVC.pushViewController(vc, animated: false)
                }
            }else if let parentVC = self.presentingViewController as? CustomCameraVC, !self.isFirstVC {
                self.dismiss(animated: false) {
                    parentVC.present(vc, animated: false, completion: nil)
                }
            }
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
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("End scroll\(  scrollView.contentOffset)")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("End decelerate \(  scrollView.contentOffset)")
    }
    
}
