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
    var paymentSheet: PaymentSheet?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.configureButton(title: "Loading...", isEnabled: false)
        self.fetchStripeConfiguration()
    }
    
    private func configureButton(title: String, isEnabled: Bool) {
        self.navigationFooterConfig = NavigationFooterView.Config(primaryButton: ButtonConfig(isEnabled: isEnabled, style: .primary, title: title, action: didTapCheckoutButton),
                                                                  secondaryButton: nil,
                                                                  hasBlurredBackground: false)
    }
    
    private func fetchStripeConfiguration() {
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
                
                var configuration = PaymentSheet.Configuration()
                configuration.customer = .init(id: response.customer, ephemeralKeySecret: response.ephemeralKey)
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: response.paymentIntent, configuration: configuration)

                DispatchQueue.main.async {
                    self.configureButton(title: "Pay with Stripe", isEnabled: true)
                }
            case .failure(let error):
                self.show(error)
            }
        }
    }
    
    private func didTapCheckoutButton() {
        paymentSheet?.present(from: self) { paymentResult in
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
