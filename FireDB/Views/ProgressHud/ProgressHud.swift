//
//  ProgressHud.swift
//  FireDB
//
//  Created by admin on 21/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class ProgressHud: UIView {
    
    @IBOutlet weak var lblViewBackground: UIView!
    @IBOutlet weak var viewActivity: UIActivityIndicatorView!
    @IBOutlet weak var lblDetails: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var activityView : ProgressHud?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func nibSetup() {
        activityView = Bundle.main.loadNibNamed("ProgressHud", owner: nil, options: nil)![0] as? ProgressHud
        activityView?.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        activityView?.viewActivity.transform = CGAffineTransform(scaleX: 2, y: 2)
        addSubview(activityView!)
    }
    
    func showActivity() {
        self.removeFromSuperview()
        self.activityView?.viewActivity.startAnimating()
        UIApplication.shared.keyWindow?.addSubview(self)
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func showActivity(withDetails text : String) {
        self.lblDetails?.text = text
        self.showActivity()
    }
    
    func hideActivity() {
        self.activityView?.viewActivity.stopAnimating()
        self.removeFromSuperview()
        self.lblDetails?.text = ""
        if UIApplication.shared.isIgnoringInteractionEvents {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    
}
