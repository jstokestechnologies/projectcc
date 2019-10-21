//
//  BackendAPIAdapter.swift
//  Standard Integration
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {
    enum APIError: Error {
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .unknown:
                return "Unknown error"
            }
        }
    }

    static let sharedClient = MyAPIClient()
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    func createPaymentIntent(shippingMethod: PKShippingMethod?, amount : Int, country: String? = nil, completion: @escaping ((Result<String, Error>) -> Void)) {
        var url = self.baseURL.appendingPathComponent(URLPaymentIntent)
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)! //cus_G0wB7Ps2IeYt1h
        urlComponents.queryItems = [URLQueryItem(name: "amount", value: "\(amount)")]
        
        url = urlComponents.url!
        
        var params: [String: Any] = [
            "metadata": [
                // example-ios-backend allows passing metadata through to Stripe
                "payment_request_id": "B3E611D1-5FA1-4410-9CEC-00958A5126CD",
            ],
        ]
        params["amount"] = amount
        params["products"] = "Old iPhone"
        if let shippingMethod = shippingMethod {
            params["shipping"] = shippingMethod.identifier
        }
        params["country"] = country
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 45.0
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??),
                let secret = json?["client_secret"] as? String else {
                    completion(.failure(error ?? APIError.unknown))
                    return
            }
            completion(.success(secret))
        })
        task.resume()
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent( URLEphemeralKeys)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)! //cus_G0wB7Ps2IeYt1h
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion), URLQueryItem(name: "customerId", value: "cus_G0wRRopEU12mzU")]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
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
        })
        task.resume()
    }

}