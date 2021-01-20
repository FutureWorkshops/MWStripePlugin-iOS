//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeViewController: ORKInstructionStepViewController {
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.step as! MWStripeStep }
    private var stripeAPIClient: MWStripeAPIClient! // Force-unwrapped because we need access to self
    private var hasAskedForPaymentOptionsAlready = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Get the identifier from the selected product that triggered this flow
        let productToBuy = MWStripeProduct(identifier: "1")
        
        self.stripeAPIClient = MWStripeAPIClient(step: self.stripeStep, product: productToBuy)
        self.stripeAPIClient.delegate = self
        self.stripeAPIClient.paymentContextHostViewController = self
        
        // Hijack the default target/action and call the method that we need
        self.continueButtonTitle = "Loading Payment Options..."
        self.continueButtonItem?.target = self
        self.continueButtonItem?.action = #selector(self.requestPayment)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ask only once
        guard !hasAskedForPaymentOptionsAlready else { return }
        // Automatically trigger the payment options
        // warning: This can't be called on viewDidLoad or viewWillAppear because the UIViewController doesn't have
        // a `.window` yet and the Stripe SDK asserts on that
        self.stripeAPIClient.presentPaymentOptionsViewController()
        self.hasAskedForPaymentOptionsAlready = true
    }
    
    @objc private func requestPayment() {
        self.continueButtonTitle = "Hold on..."
        self.stripeAPIClient.requestPayment()
    }
}

extension MWStripeViewController: MWStripeAPIClientDelegate {
    public func paymentContextDidFailToLoad(withError error: Error) {
        let alertController = UIAlertController(title: "Failed to load", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            if self?.navigationController?.viewControllers.first === self {
                self?.dismiss(animated: true)
            } else {
                self?.goBackward()
            }
        })
        self.present(alertController, animated: true)
    }
    
    public func paymentContextDidChange(isLoading: Bool, selectedPaymentOptionLabel: String?) {
        if let selectedPaymentOption = selectedPaymentOptionLabel {
            self.continueButtonTitle = "Pay with \(selectedPaymentOption)"
        }
    }
    
    public func paymentContextDidFinishWith(result: PaymentContextResult) {
        switch result {
        case .userCancelled:
            if self.navigationController?.viewControllers.first === self {
                self.dismiss(animated: true)
            } else {
                self.goBackward()
            }
        case .success, .error:
            let success: Bool
            switch result {
            case .success: success = true
            default: success = false
            }
            let purchaseResult = MWStripePurchaseResult(identifier: self.stripeStep.identifier, success: success)
            self.addResult(purchaseResult)
            self.goForward()
        }
    }
}
