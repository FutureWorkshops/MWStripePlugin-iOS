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
    
    //MARK: IBOutlets
    private let buyButton = UIButton(type: .system)
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.step as! MWStripeStep }
    private var customerContext: STPCustomerContext?
    private var paymentContext: STPPaymentContext?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.buyButton.setTitle("Trigger Buy Flow", for: .normal)
        self.buyButton.addTarget(self, action: #selector(buyButtonTapped(_:)), for: .primaryActionTriggered)
        self.buyButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.buyButton)
        self.buyButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.buyButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        // Step 1 - Provide a publishable key to set up the SDK: https://stripe.com/docs/mobile/ios/basic#setup-ios
        StripeAPI.defaultPublishableKey = self.stripeStep.publishableKey
        
        // Step 3 - Set up an STPCustomerContext: https://stripe.com/docs/mobile/ios/basic#set-up-customer-context
        self.customerContext = STPCustomerContext(keyProvider: self)
        
        // Step 4 - Set up an STPPaymentContext: https://stripe.com/docs/mobile/ios/basic#initialize-payment-context
        self.paymentContext = STPPaymentContext(customerContext: self.customerContext!)
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = self
        self.paymentContext?.paymentAmount = 5000 // This is in cents, i.e. $50
    }
    
    //MARK: IBActions
    @IBAction private func buyButtonTapped(_ sender: UIButton) {
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
}

// MARK: Stripe API

// Step 2 - Set up an ephemeral key: https://stripe.com/docs/mobile/ios/basic#ephemeral-key
extension MWStripeViewController: STPCustomerEphemeralKeyProvider {
    public func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard var urlComponents = URLComponents(url: self.stripeStep.ephemeralKeyURL, resolvingAgainstBaseURL: false) else {
            completion(nil, MWStripeError.failedToConstructEphemeralURL)
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        
        //FIXME: Temporarly include a hardcoded email & customer ID
        var extraQueryItems = urlComponents.queryItems
        extraQueryItems?.append(URLQueryItem(name: "email", value: "matt@futureworkshops.com"))
        extraQueryItems?.append(URLQueryItem(name: "customer_id", value: "cus_Il1PzN4kcyTooT"))
        urlComponents.queryItems = extraQueryItems
        
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

extension MWStripeViewController: STPPaymentContextDelegate {
    public func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print(#function)
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print(#function)
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        print(#function)
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print(#function)
    }
}

// MARK: Errors
enum MWStripeError: LocalizedError {
    case failedToConstructEphemeralURL
    
    var errorDescription: String? {
        switch self {
        case .failedToConstructEphemeralURL: return "Failed to construct the URL to retrieve the ephemeral key."
        }
    }
}
