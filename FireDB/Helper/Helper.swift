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
            let data = try NSKeyedArchiver.archivedData(withRootObject: dataObject, requiringSecureCoding: false)
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

}
