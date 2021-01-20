//
//  MWStripeAPIClient.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 19/1/21.
//

import Foundation
import Stripe

public enum PaymentContextResult {
    case success
    case error(error: Error)
    case userCancelled
}

public protocol MWStripeAPIClientDelegate: class {
    func paymentContextDidFailToLoad(withError error: Error)
    func paymentContextDidChange(isLoading: Bool, selectedPaymentOptionLabel: String?)
    func paymentContextDidFinishWith(result: PaymentContextResult)
}

public struct MWStripeProduct {
    let identifier: String
    //FIXME: Change this hardcoded value when we support getting the price from the server
    /// In cents, check STPPaymentContext.getter:paymentAmount for more info
    let price: Int = 1000
    //FIXME: Change this hardcoded value when we support multiple currencies
    /// Three letter symbol, check STPPaymentContext.getter:paymentCurrency for more info
    let currency = "USD"
}

public final class MWStripeAPIClient: NSObject {
    
    //MARK: Public properties
    public weak var delegate: MWStripeAPIClientDelegate?
    public var paymentContextHostViewController: UIViewController? {
        set { self.paymentContext?.hostViewController = newValue }
        get { self.paymentContext?.hostViewController }
    }

    //MARK: Private properties
    private let step: MWStripeStep
    private let product: MWStripeProduct
    private var customerContext: STPCustomerContext?
    private var paymentContext: STPPaymentContext?
    
    //MARK: Lifecycle
    public init(step: MWStripeStep, product: MWStripeProduct) {
        self.step = step
        self.product = product
        
        // Step 1 - Provide a publishable key to set up the SDK: https://stripe.com/docs/mobile/ios/basic#setup-ios
        StripeAPI.defaultPublishableKey = step.publishableKey
        
        super.init()
        
        // Step 3 - Set up an STPCustomerContext: https://stripe.com/docs/mobile/ios/basic#set-up-customer-context
        self.customerContext = STPCustomerContext(keyProvider: self)
        
        // Step 4 - Set up an STPPaymentContext: https://stripe.com/docs/mobile/ios/basic#initialize-payment-context
        self.paymentContext = STPPaymentContext(customerContext: self.customerContext!)
        self.paymentContext?.delegate = self
        self.paymentContext?.paymentAmount = self.product.price
        self.paymentContext?.paymentCurrency = self.product.currency
    }
    
    // MARK: Methods to interact with the UI
    // Step 5 - Handle the user's payment method: https://stripe.com/docs/mobile/ios/basic#handle-payment-method
    @objc public func presentPaymentOptionsViewController() {
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
    // Step 6 - Submit the payment: https://stripe.com/docs/mobile/ios/basic#submit-payment
    @objc public func requestPayment() {
        self.paymentContext?.requestPayment()
    }
}

// MARK: STPCustomerEphemeralKeyProvider
// Step 2 - Set up an ephemeral key: https://stripe.com/docs/mobile/ios/basic#ephemeral-key
extension MWStripeAPIClient: STPCustomerEphemeralKeyProvider {
    // This method is called automatically after you create an `STPCustomerContext`
    public func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        var urlComponents = URLComponents(url: self.step.ephemeralKeyURL, resolvingAgainstBaseURL: false)!
        
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        
        //FIXME: Temporarly include a hardcoded email & customer ID
        var extraQueryItems = urlComponents.queryItems
        extraQueryItems?.append(URLQueryItem(name: "email", value: "matt@futureworkshops.com"))
        extraQueryItems?.append(URLQueryItem(name: "customer_id", value: self.step.customerID))
        urlComponents.queryItems = extraQueryItems
        
        var request = URLRequest(url: urlComponents.url!)
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

// MARK: STPPaymentContextDelegate
extension MWStripeAPIClient: STPPaymentContextDelegate {
    public func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        self.delegate?.paymentContextDidChange(isLoading: paymentContext.loading, selectedPaymentOptionLabel: paymentContext.selectedPaymentOption?.label)
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
        var components = URLComponents(url: self.step.paymentIntentURL, resolvingAgainstBaseURL: false)!
        
        //FIXME: This is temporary
        components.queryItems = [
            URLQueryItem(name: "email", value: "matt@futureworkshops.com"),
            URLQueryItem(name: "customer_id", value: self.step.customerID),
            URLQueryItem(name: "product_id", value: self.product.identifier)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
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
            self.delegate?.paymentContextDidFinishWith(result: .success)
        case .error:
            self.delegate?.paymentContextDidFinishWith(result: .error(error: error ?? NSError(domain: "io.mobileworkflow.stripe", code: 0, userInfo: [NSLocalizedDescriptionKey:"Payment context failed but there was no error returned by Stripe."])))
        case .userCancellation:
            self.delegate?.paymentContextDidFinishWith(result: .userCancelled)
        }
    }
    
    public func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        self.delegate?.paymentContextDidFailToLoad(withError: error)
    }
}
