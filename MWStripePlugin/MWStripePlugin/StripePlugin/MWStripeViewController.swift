//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeViewController: MWInstructionStepViewController {
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.mwStep as! MWStripeStep }
    private var stripeAPIClient: MWStripeAPIClient! // Force-unwrapped because we need access to self
    private var hasAskedForPaymentOptionsAlready = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stripeAPIClient = MWStripeAPIClient(step: self.stripeStep, session: self.stripeStep.session)
        self.stripeAPIClient.delegate = self
        self.stripeAPIClient.paymentContextHostViewController = self
        
        self.updateButtonTitle(buttonTitle: L10n.Stripe.loadingButtonTitle)
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
    
    private func updateButtonTitle(buttonTitle: String) {
        self.configureWithTitle(
            self.mwStep.title ?? "",
            body: self.mwStep.text ?? "",
            buttonTitle: buttonTitle) { [weak self] in
            self?.requestPayment()
        }
    }
    
    @objc private func requestPayment() {
        self.updateButtonTitle(buttonTitle: L10n.Stripe.payingButtonTitle)
        self.stripeAPIClient.requestPayment()
    }
}

extension MWStripeViewController: MWStripeAPIClientDelegate {
    public func paymentContextDidFailToLoad(withError error: Error) {
        let alertController = UIAlertController(title: L10n.Stripe.loadingError, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: L10n.Stripe.dismissButtonTitle, style: .default) { [weak self] _ in
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
            self.updateButtonTitle(buttonTitle: L10n.Stripe.payWithOption(selectedPaymentOption))
        }
    }
    
    public func paymentContextDidFinishWith(result: PaymentContextResult) {
        switch result {
        case .userCancelled:
            self.goBackward()
        case .success, .error:
            let success: Bool
            switch result {
            case .success: success = true
            default: success = false
            }
            let purchaseResult = MWStripePurchaseResult(identifier: self.stripeStep.identifier, success: success)
            self.addStepResult(purchaseResult)
            self.goForward()
        }
    }
}
