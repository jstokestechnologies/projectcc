//
//  PaymentVC.swift
//  FireDB
//
//  Created by admin on 17/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Stripe

class PaymentVC: UIViewController {
    let customerContext = STPCustomerContext(keyProvider: MyAPIClient.sharedClient)
    
    init() {
        self.paymentContext = STPPaymentContext(customerContext: customerContext)
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentAmount = 5000 // This is in cents, i.e. $50 USD
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

extension PaymentVC {
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        if let url = (URL.init(string: "www.google.com"))?.appendingPathComponent("ephemeral_keys") {
            
            let request = URLRequest(url: url)
            let config = URLSessionConfiguration.default
            let session =  URLSession(configuration: config)
            
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if let data = data, error == nil {
                    do {
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        completion(jsonData as? [String : AnyObject], nil)
                    }catch {
                        print(error.localizedDescription)
                        completion(nil, error)
                    }
                }else {
                    completion(nil, error)
                }
            });
            task.resume()
        }
    }
}

extension PaymentVC : STPPaymentContextDelegate {
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print(paymentContext.paymentAmount)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        print(paymentResult.paymentMethod.allResponseFields)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        if error == nil {
            print(status)
        }
    }
}
