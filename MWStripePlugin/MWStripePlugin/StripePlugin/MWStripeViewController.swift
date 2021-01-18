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
        
        self.configureBuyButtonToSelectPaymentOption()
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
    
    private func configureBuyButtonToSelectPaymentOption() {
        self.buyButton.setTitle("Buy Item", for: .normal)
        self.buyButton.removeTarget(nil, action: nil, for: .allEvents)
        self.buyButton.addTarget(self, action: #selector(buyButtonTappedToTriggerSelectionOfPaymentOption(_:)), for: .primaryActionTriggered)
    }
    
    private func configureBuyButtonToBuy(usingPaymentOption paymentOption: STPPaymentOption) {
        self.buyButton.setTitle("Buy Item using \(paymentOption.label)", for: .normal)
        self.buyButton.removeTarget(nil, action: nil, for: .allEvents)
        self.buyButton.addTarget(self, action: #selector(buyButtonTappedToConfirmPurchase(_:)), for: .primaryActionTriggered)
    }
    
    //MARK: IBActions
    @IBAction private func buyButtonTappedToTriggerSelectionOfPaymentOption(_ sender: UIButton) {
        // Step 5 - Handle the user's payment method: https://stripe.com/docs/mobile/ios/basic#handle-payment-method
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
    @IBAction private func buyButtonTappedToConfirmPurchase(_ sender: UIButton) {
        // Step 6 - Submit the payment: https://stripe.com/docs/mobile/ios/basic#submit-payment
        self.paymentContext?.requestPayment()
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
        print("paymentContextDidChange, isLoading: \(paymentContext.loading)")
        if let selectedPaymentOption = paymentContext.selectedPaymentOption {
            self.configureBuyButtonToBuy(usingPaymentOption: selectedPaymentOption)
        } else {
            self.configureBuyButtonToSelectPaymentOption()
        }
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        // Call the createPaymentIntent
        // Confirm the purchase when the result is sucess
        
        //FIXME: This should come from the step
        let baseURL = URL(string: "https://mw-stripe-dev1.herokuapp.com/create_payment_intent")!
        
        //FIXME: Get the real ID of the products that we're purchasing
        let productIDs = [1]
        
        var request = URLRequest(url: baseURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: productIDs)
        
        let task = URLSession.shared.dataTask(with: request) { dataOrNil, urlResponseOrNil, errorOrNil in
            if let response = urlResponseOrNil as? HTTPURLResponse, response.statusCode == 200, let data = dataOrNil, let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String: Any]??), let secret = json?["secret"] as? String {
                
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: secret)
                paymentIntentParams.paymentMethodId = paymentResult.paymentMethod?.stripeId
                
                STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: paymentContext) { paymentStatus, paymentIntent, paymentError in
                    switch paymentStatus {
                    case .succeeded:
                        completion(.success, nil)
                    case .failed:
                        completion(.error, paymentError)
                    case .canceled:
                        completion(.userCancellation, nil)
                    @unknown default:
                        assertionFailure("Unhandled case")
                        completion(.error, nil)
                    }
                }
                
            } else {
                completion(.error, errorOrNil)
            }
        }
        task.resume()
        
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        switch status {
        case .success:
            let alertController = UIAlertController(title: "Success", message: "Successfully purchased the product.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alertController, animated: true)
        case .error:
            let alertController = UIAlertController(title: "Error", message: error?.localizedDescription ?? "UNKNOWN ERROR", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alertController, animated: true)
        case .userCancellation:
            print("User cancelled the payment, do nothing")
        }
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        assertionFailure("Failed to load the Payment Context")
        self.dismiss(animated: true)
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
