//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeViewController: ORKStepViewController {
    
    //MARK: IBOutlets
    private let buyButton = UIButton(type: .system)
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.step as! MWStripeStep }
    private var stripeAPIClient: MWStripeAPIClient! // Force-unwrapped because we need access to self
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stripeAPIClient = MWStripeAPIClient(step: self.stripeStep)
        self.stripeAPIClient.delegate = self
        self.stripeAPIClient.paymentContextHostViewController = self
        
        self.configureBuyButtonToSelectPaymentOption()
        self.buyButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.buyButton)
        self.buyButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.buyButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
    private func configureBuyButtonToSelectPaymentOption() {
        self.buyButton.setTitle("Buy Item", for: .normal)
        self.buyButton.removeTarget(nil, action: nil, for: .allEvents)
        self.buyButton.addTarget(self, action: #selector(presentPaymentOptions), for: .primaryActionTriggered)
    }
    
    private func configureBuyButtonToBuy(usingSelectedPaymentOption paymentOptionLabel: String) {
        self.buyButton.setTitle("Buy Item using \(paymentOptionLabel)", for: .normal)
        self.buyButton.removeTarget(nil, action: nil, for: .allEvents)
        self.buyButton.addTarget(self, action: #selector(requestPayment), for: .primaryActionTriggered)
    }
    
    @objc private func presentPaymentOptions() {
        self.stripeAPIClient.presentPaymentOptionsViewController()
    }
    
    @objc private func requestPayment() {
        self.stripeAPIClient.requestPayment()
    }
}

extension MWStripeViewController: MWStripeAPIClientDelegate {
    public func paymentContextDidFailToLoad(withError error: Error) {
        let alertController = UIAlertController(title: "Failed to load", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            self?.goBackward()
        })
        self.present(alertController, animated: true)
    }
    
    public func paymentContextDidChange(isLoading: Bool, selectedPaymentOptionLabel: String?) {
        if let selectedPaymentOption = selectedPaymentOptionLabel {
            self.configureBuyButtonToBuy(usingSelectedPaymentOption: selectedPaymentOption)
        } else {
            self.configureBuyButtonToSelectPaymentOption()
        }
    }
    
    public func paymentContextDidFinishWith(result: PaymentContextResult) {
        let message: String
        switch result {
        case .success: message = "Successfully purchased the product"
        case .error(let error): message = error.localizedDescription
        case .userCancelled: message = "User cancelled the purchase"
        }
        let alertController = UIAlertController(title: "Purchase Result", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alertController, animated: true)
    }
}
