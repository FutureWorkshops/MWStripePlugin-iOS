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
    let success: Bool
    
    init(identifier: String, success: Bool) {
        self.identifier = identifier
        self.success = success
    }
}

extension MWStripePurchaseResult: JSONRepresentable {
    
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension MWStripePurchaseResult: ValueProvider {
    
    var content: [AnyHashable: Codable] {
        return [self.identifier: [CodingKeys.success.stringValue: success]]
    }
    
    func fetchValue(for path: String) -> Any? {
        if path == CodingKeys.success.stringValue {
            return self.success
        } else {
            return nil
        }
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        if path == CodingKeys.success.stringValue {
            return self.success as? ValueProvider
        } else {
            return nil
        }
    }
}
