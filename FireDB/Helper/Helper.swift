//
//  Helper.swift
//  FireDB
//
//  Created by admin on 12/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit
import InstantSearchClient

var progressView = ProgressHud()

class HelperClass : NSObject {
    
    typealias ABCompletionBlock = (_ result: NSDictionary, _ message: String, _ success: Bool) -> Void
    
    typealias AlgoliaComplition = (_ content: [String : Any]?, _ error: Error?) -> Void
    
    class func writeArrayToJsonFile(data : [NSDictionary]) {
        let documentsDirectoryPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documentsDirectoryPathString)!
        print(documentsDirectoryPathString)
        guard let jsonFilePath = documentsDirectoryPath.appendingPathComponent("item_data.json") else { return }
        
        // creating JSON out of the above array
        var jsonData: Data!
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions())
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            print(jsonString ?? "N/A")
        } catch let error as NSError {
            print("Array to JSON conversion failed: \(error.localizedDescription)")
        }
        
        // Write that JSON to the file created earlier
        do {
            let file = try FileHandle(forWritingTo: jsonFilePath)
            file.write(jsonData)
            print("JSON data was written to teh file successfully!")
        } catch let error as NSError {
            print("Couldn't write to file: \(error.localizedDescription)")
        }
    }
    
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
        self.setUserDataModel(userDict: dataObject)
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
    
    class func setUserDataModel(userDict : NSDictionary) {
        do {
            let jsonData  = try? JSONSerialization.data(withJSONObject: userDict, options:.prettyPrinted)
            let jsonDecoder = JSONDecoder()
            //                                    var userdata = UserData.sharedInstance
            userdata = try jsonDecoder.decode(UserData.self, from: jsonData!)
            print(userdata.id)
        }
        catch {
            print(error.localizedDescription)
        }
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
    
    class func requestForAllApiWithBody( param : NSDictionary, serverUrl urlString : String, vc : UIViewController, completionHandler : @escaping ABCompletionBlock) -> Void {
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        
        let jsonData: Data? = try? JSONSerialization.data(withJSONObject: param, options:.prettyPrinted)
        
        
        let myString = String(data: jsonData!, encoding: String.Encoding.utf8)
        
        print("Request URL: \(urlString)")
        print("Data: \(myString!)")
        
        var request = URLRequest(url: URL(string: urlString)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 45)
        
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.timeoutInterval = 45
        var postDataTask = URLSessionDataTask()
//        postDataTask.priority = URLSessionDataTask.highPriority
        
        postDataTask = session.dataTask(with: request, completionHandler: { (data : Data?,response : URLResponse?, error : Error?) in
            //            var json : (Any);
            if data != nil && response != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    let results = try? JSONSerialization.jsonObject(with: data!, options: [])
                    let jsonData: Data? = try? JSONSerialization.data(withJSONObject: results! , options: .prettyPrinted)
                    let myString = String(data: jsonData!, encoding: String.Encoding.utf8)
                    print("Result: \(myString ?? "")")
                    
                    let data = json as? Array<Any>
                    let status = data != nil
                    let message = data != nil ? "" : "No data found"
                    
                    if let result = data, status {
                        completionHandler(["array" : result], message, status)
                    } else {
                        completionHandler([:], message, status)
                    }
                    
                }catch {
                    print(error.localizedDescription)
                    HelperClass.showAlert(msg: error.localizedDescription, isBack: false, vc: vc)
                }
            }else if error != nil {
                print((error?.localizedDescription)!)
                completionHandler([:],(error?.localizedDescription)!, false)
            }else {
                completionHandler([:], "Unknown error occurd" , false)
            }
        })
        postDataTask.resume()
    }
    
    //MARK: - Algolia Search
    class func searchItemWith(text : String, index : Index!, itemPerPage : Int, pageNo : Int, completion : @escaping AlgoliaComplition) -> Operation? {
        
        let query = Query.init(query: text)
        query.hitsPerPage = itemPerPage.magnitude
        query.page = pageNo.magnitude
        
        let searchTask = index.search(query, completionHandler: { (content, error) -> Void in
            if content != nil {
                completion(content, error)
            }else {
                completion(content, error)
                print("Result: \(error?.localizedDescription ?? "Error")")
            }
        })
        return searchTask
    }
}


@IBDesignable extension UIView {
    
    @IBInspectable var borderColor:UIColor? {
        set {
            layer.borderColor = newValue!.cgColor
        }
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor:color)
            }
            else {
                return nil
            }
        }
    }
    
    @IBInspectable var borderWidth:CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius:CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
        
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
            layer.masksToBounds = false
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    
}
