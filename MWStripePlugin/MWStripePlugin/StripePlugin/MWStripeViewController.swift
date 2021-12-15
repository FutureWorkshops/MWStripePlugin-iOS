//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Stripe
import Foundation
import MobileWorkflowCore

struct StripeConfigurationResponse: Decodable {
    let paymentIntent: String
    let ephemeralKey: String
    let customer: String
    let publishableKey: String
}

public class MWStripeViewController: MWInstructionStepViewController {
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.mwStep as! MWStripeStep }
    private let checkoutButton = UIButton(type: .system)
    var paymentSheet: PaymentSheet?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        checkoutButton.setTitle("Pay with Stripe", for: .normal)
        checkoutButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .primaryActionTriggered)
        checkoutButton.isEnabled = false
        self.view.addSubview(checkoutButton)
        NSLayoutConstraint.activate([
            checkoutButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            checkoutButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        // MARK: Fetch the PaymentIntent client secret, Ephemeral Key secret, Customer ID, and publishable key
        guard let url = self.stripeStep.session.resolve(url: stripeStep.configurationURLString) else {
            assertionFailure("Failed to resolve the URL")
            return
        }
        
        let task = URLAsyncTask<StripeConfigurationResponse>.build(
            url: url,
            method: .GET,
            session: stripeStep.session,
            parser: { try StripeConfigurationResponse.parse(data: $0) }
        )
        
        self.stripeStep.services.perform(task: task, session: stripeStep.session) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                STPAPIClient.shared.publishableKey = response.publishableKey
                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Example, Inc."
                configuration.customer = .init(id: response.customer, ephemeralKeySecret: response.ephemeralKey)
                // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
                // methods that complete payment after a delay, like SEPA Debit and Sofort.
                configuration.allowsDelayedPaymentMethods = false
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: response.paymentIntent, configuration: configuration)
                
                DispatchQueue.main.async {
                    self.checkoutButton.isEnabled = true
                }
            case .failure(let error):
                self.show(error)
            }
        }
    }
    
    @objc
    private func didTapCheckoutButton() {
      // MARK: Start the checkout process
      paymentSheet?.present(from: self) { paymentResult in
        // MARK: Handle the payment result
        switch paymentResult {
        case .completed:
          print("Your order is confirmed")
        case .canceled:
          print("Canceled!")
        case .failed(let error):
          print("Payment failed: \(error)")
        }
      }
    }
}
