//
//  Helper.swift
//  FireDB
//
//  Created by admin on 12/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit

var progressView = ProgressHud()

class HelperClass : NSObject {
    class func saveDataToDefaults(dataObject: NSDictionary, key : String) {
        do {
            let currentDefaults = UserDefaults.standard
            var data : Data?
            if #available(iOS 11.0, *) {
                data = try NSKeyedArchiver.archivedData(withRootObject: dataObject, requiringSecureCoding: false)
            } else {
                data = NSKeyedArchiver.archivedData(withRootObject: dataObject)
            }
            currentDefaults.set(data, forKey: key)
            currentDefaults.set(true, forKey: kIsLoggedIn)
            currentDefaults.synchronize()
        }catch {
            
        }
    }
    
    class func fetchDataFromDefaults(with key : String)->NSDictionary {
        let currentDefaults = UserDefaults.standard
        
        if let data = currentDefaults.value(forKey: key) as? Data {
            do {
                let dict = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
                return  dict as? NSDictionary ?? NSDictionary()
            }
        }
        return  NSDictionary()
    }
    
    
    class func showAlert(msg : String, isBack : Bool, vc : UIViewController?){
        let alert = UIAlertController.init(title: "", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (alrt) in
            if isBack {
                if vc?.navigationController != nil {
                    if (vc?.navigationController!.isBeingPresented)! && vc?.navigationController?.viewControllers.count == 1 {
                        vc?.navigationController?.dismiss(animated: true, completion: nil)
                    }else {
                        vc?.navigationController?.popViewController(animated: true)
                    }
                }else {
                    vc?.dismiss(animated: true, completion: nil)
                }
            }
        }))
        DispatchQueue.main.async {
            if vc != nil {
                vc?.present(alert, animated: true, completion: nil)
            }
//            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
