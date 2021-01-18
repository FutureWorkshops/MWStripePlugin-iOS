//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import Stripe
import MobileWorkflowCore

public class MWStripeViewController: ORKStepViewController {
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.step as! MWStripeStep }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 1 - Provide a publishable key to set up the SDK
        StripeAPI.defaultPublishableKey = self.stripeStep.publishableKey
    }
    
}

// MARK: Stripe API
enum MWStripeError: LocalizedError {
    case failedToConstructEphemeralURL
    
    var errorDescription: String? {
        switch self {
        case .failedToConstructEphemeralURL: return "Failed to construct the URL to retrieve the ephemeral key."
        }
    }
}

// Step 2 - Set up an ephemeral key: https://stripe.com/docs/mobile/ios/basic#ephemeral-key
extension MWStripeViewController: STPCustomerEphemeralKeyProvider {
    public func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard var urlComponents = URLComponents(url: self.stripeStep.ephemeralKeyURL, resolvingAgainstBaseURL: false) else {
            completion(nil, MWStripeError.failedToConstructEphemeralURL)
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        
        guard let finalURL = urlComponents.url else {
            completion(nil, MWStripeError.failedToConstructEphemeralURL)
            return
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { dataOrNil, urlResponseOrNil, errorOrNil in
            if let response = urlResponseOrNil as? HTTPURLResponse, response.statusCode == 200, let data = dataOrNil, let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??) {
                completion(json, nil)
            } else {
                completion(nil, errorOrNil)
            }
        }
        task.resume()
    }
}
