//
//  PaymentVC.swift
//  FireDB
//
//  Created by admin on 17/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import FirebaseMessaging
import Stripe

class PaymentVC: UIViewController {
    
    var stripePublishableKey = ""
    var backendBaseURL: String? = nil
    var appleMerchantID: String? = ""
    
    var isPageLoaded = 1
    
    var paymentContext: STPPaymentContext?
    var amount = 0
    
    var productId = ""
    var productName = ""
    var productIndex = Int()
    
    var sellerId = ""
    var sellerDtoken = ""
    
    var parentVC : ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchSellerDeviceToken()
        progressView.showActivity(withDetails: "Initiating payment")
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
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    @IBAction func choosePaymentButtonTapped(_ sender : UIButton) {
        self.paymentContext?.pushPaymentOptionsViewController()
//        isPageLoaded = true
    }
    
    func fetchSellerDeviceToken() {
        db.collection(kUsersCollection).document(self.sellerId).getDocument { (snap, error) in
            if let doc = snap {
                if let sellerData = doc.data() {
                    self.sellerDtoken = sellerData["fcm_token"] as? String ?? ""
                }
            }
        }
    }
    
    func notifySeller() {
        progressView.showActivity(withDetails: "Finalising payment")
        let msgBody = ["aps" : [
            "alert" : "\(userdata.name) has paid $\(self.amount) for \(self.productName). Dispatch/deliver it to finish the transaction.",
                                    "badge" : 0,
                                    "sound" : "default"
                                ]]
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let msgId = "\(userdata.id)\(timestamp)"
        Messaging.messaging().sendMessage(msgBody, to: self.sellerDtoken + "@fcm.googleapis.com", withMessageID: msgId, timeToLive: Int64(7200 + timestamp))
        progressView.hideActivity()
        self.paymentSuccess()
    }
    
    func paymentSuccess() {
        HelperClass.showAlert(msg: "Payment authorization successfull. Payment will be deducted once item will be shipped.", isBack: true, vc: self)
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
                progressView.showActivity(withDetails: "Authenticating payment")
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
                        let paymentDetails = ["index" : self.productIndex,
                                              "id"    : self.productId,
                                              "paymentId" : paymentIntent?.stripeId ?? ""] as [String : Any]
                        NotificationCenter.default.post(name: NSNotification.Name(kNotification_PaySuccess), object: nil, userInfo: paymentDetails)
                        self.notifySeller()
                    // Payment Intent is confirmed
                    default:
                        print("unknown error")
                    }
                    DispatchQueue.main.async {
                        progressView.hideActivity()
                        
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
