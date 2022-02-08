//
//  MWStripePurchaseResult.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 19/1/21.
//

import Foundation
import MobileWorkflowCore

final class MWStripePurchaseResult: StepResult, Codable {
    
    var identifier: String
    let paymentSuccessful: Bool
    let paymentStatusMessage: String?
    
    init(identifier: String, paymentSuccessful: Bool, paymentStatusMessage: String?) {
        self.identifier = identifier
        self.paymentSuccessful = paymentSuccessful
        self.paymentStatusMessage = paymentStatusMessage
    }
}

extension MWStripePurchaseResult: JSONRepresentable {
    
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension MWStripePurchaseResult: ValueProvider {

    func fetchValue(for path: String) -> Any? {
        if path == CodingKeys.paymentSuccessful.stringValue {
            return self.paymentSuccessful
        } else  if path == CodingKeys.paymentStatusMessage.stringValue {
            return self.paymentStatusMessage
        } else {
            return nil
        }
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        if path == CodingKeys.paymentSuccessful.stringValue {
            return self.paymentSuccessful as? ValueProvider
        } else  if path == CodingKeys.paymentStatusMessage.stringValue {
            return self.paymentStatusMessage as? ValueProvider
        } else {
            return nil
        }
    }
}
