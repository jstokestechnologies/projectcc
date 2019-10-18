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
    
    
    
    var paymentContext: STPPaymentContext?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stripePublishableKey = "pk_test_4dJsL1teFhhtbNF8QaoyGlCp00VXw1CfBH"
        self.backendBaseURL = "https://us-central1-projectcc-a98a4.cloudfunctions.net/createEphemeralKeys"
        // Do any additional setup after loading the view.
        MyAPIClient.sharedClient.baseURLString = self.backendBaseURL
        
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = self.stripePublishableKey
        config.appleMerchantIdentifier = self.appleMerchantID
        config.companyName = "Particle 41"
        //               config.requiredBillingAddressFields = settings.requiredBillingAddressFields
        //               config.requiredShippingAddressFields = settings.requiredShippingAddressFields
        //               config.shippingType = settings.shippingType
        //               config.additionalPaymentOptions = settings.additionalPaymentOptions
        
        let customerContext = STPCustomerContext(keyProvider: MyAPIClient.sharedClient)
        let paymentContext = STPPaymentContext(customerContext: customerContext,
                                               configuration: config,
                                               theme: .default())
//        let userInformation = STPUserInformation()
        paymentContext.paymentAmount = 350
        paymentContext.paymentCurrency = "USD"
        paymentContext.delegate = self
        paymentContext.hostViewController = self
//        let addCardFooter = PaymentContextFooterView(text: "You can add custom footer views to the add card screen.")
//        addCardFooter.theme = .default()
//        paymentContext.addCardViewControllerFooterView = addCardFooter
        
        self.paymentContext = paymentContext
        
        
    }
    
    @IBAction func choosePaymentButtonTapped(_ sender : UIButton) {
        self.paymentContext?.pushPaymentOptionsViewController()
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
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print(paymentContext.paymentAmount)
        if !paymentContext.loading {
            self.paymentContext?.pushPaymentOptionsViewController()
        }
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
