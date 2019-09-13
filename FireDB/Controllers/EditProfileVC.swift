//
//  EditProfileVC.swift
//  FireDB
//
//  Created by admin on 12/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase

class EditProfileVC: UIViewController {
    
    @IBOutlet weak var imgProfile: UIImageView!
    
    lazy var storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userdata.profile_pic = "http://graph.facebook.com/10156247148412161/picture?type=large"
        if let img = userdata.profile_pic {
            let url = URL.init(fileURLWithPath: img)
            if url.pathExtension != "" {
                let storageRef = storage.reference(withPath: img)
                self.imgProfile.sd_setImage(with: storageRef, placeholderImage: UIImage.init(named: "no-image"))
            }else {
                self.imgProfile?.sd_setImage(with: URL.init(string: img), placeholderImage: UIImage.init(named: "no-image"), options: .retryFailed, context: nil)
            }
        }
        DispatchQueue.main.async {
            self.imgProfile.layer.cornerRadius = self.imgProfile.frame.height/2
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
