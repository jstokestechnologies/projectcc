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
    
    var stripePublishableKey = ""
    var backendBaseURL: String? = nil
    var appleMerchantID: String? = ""
    
    var isPageLoaded = 1
    
    var paymentContext: STPPaymentContext?
    var amount = 0
    
    var parentVC : ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.showActivity()
        self.stripePublishableKey = kStripePublicKey
        self.backendBaseURL = kBaseURL 
        // Do any additional setup after loading the view.
        MyAPIClient.sharedClient.baseURLString = self.backendBaseURL
        
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = kStripePublicKey//self.stripePublishableKey\
        config.companyName = "Particle 41"
        config.additionalPaymentOptions = .all
        
        let customerContext = STPCustomerContext(keyProvider: MyAPIClient.sharedClient)
        let paymentContext = STPPaymentContext(customerContext: customerContext,
                                               configuration: config,
                                               theme: .default())
        paymentContext.paymentAmount = self.amount
        paymentContext.paymentCurrency = "USD"
        paymentContext.delegate = self
        paymentContext.hostViewController = self

        self.paymentContext = paymentContext
        
    }
    
    @IBAction func choosePaymentButtonTapped(_ sender : UIButton) {
        self.paymentContext?.pushPaymentOptionsViewController()
//        isPageLoaded = true
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


extension PaymentVC : STPPaymentContextDelegate {
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
        self.navigationController?.popViewController(animated: true)
        progressView.hideActivity()
        }
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print(paymentContext.paymentAmount)
        self.paymentContext = paymentContext
        
        if !paymentContext.loading {
            if isPageLoaded == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    progressView.hideActivity()
                    self.paymentContext?.pushPaymentOptionsViewController()
                }
                isPageLoaded = 2
            }else if isPageLoaded == 2 {
                progressView.showActivity()
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    self.paymentContext?.requestPayment()
                }
            }
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        print(paymentResult.paymentMethod.allResponseFields)
        MyAPIClient.sharedClient.createPaymentIntent(shippingMethod: nil, amount : self.amount, completion: { result in
            switch (result) {
            case .success(let clientSecret):
                print(clientSecret)
                // Hold onto clientSecret for Step 4
                
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentResult.paymentMethod.stripeId
                let paymentManager = STPPaymentHandler.shared()
                paymentManager.confirmPayment(paymentIntentParams, with: paymentContext, completion: { (status, paymentIntent, error) in
                    switch (status) {
                    case .failed:
                        print("failed payment")
                    // Handle error
                    case .canceled:
                        print("canceled payment")
                    // Handle cancel
                    case .succeeded:
                        print("success payment")
                    // Payment Intent is confirmed
                    default:
                        print("unknown error")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        DispatchQueue.main.async {
                            progressView.hideActivity()
                            HelperClass.showAlert(msg: "Payment authorization successfull. Payment will be deducted once item will be shipped.", isBack: true, vc: self)
                        }
                    }
                })
                
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    progressView.hideActivity()
                }
            }
        })
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        switch status {
        case .error:
            print(error?.localizedDescription ?? "error")
        case .success:
            print("payement success")
        case .userCancellation:
            print("payement canceled")
            return // Do nothing
        default:
            print("unknown error")
        }
    }
}
