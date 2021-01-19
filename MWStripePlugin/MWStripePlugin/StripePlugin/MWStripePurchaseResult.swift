//
//  MWStripePurchaseResult.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 19/1/21.
//

import Foundation
import MobileWorkflowCore

private let kSuccess = "success"

final class MWStripePurchaseResult: ORKResult, Codable {
    
    let success: Bool
    
    init(identifier: String, success: Bool) {
        self.success = success
        super.init(identifier: identifier)
    }
    
    override func copy() -> Any {
        return MWStripePurchaseResult(identifier: self.identifier, success: self.success)
    }
    
    required init?(coder: NSCoder) {
        self.success = coder.decodeBool(forKey: kSuccess)
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.success, forKey: kSuccess)
        super.encode(with: coder)
    }
}

extension MWStripePurchaseResult: JSONRepresentable {
    
    var jsonContent: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension MWStripePurchaseResult: ValueProvider {
    
    var content: [AnyHashable : Codable] {
        return [self.identifier: [kSuccess: success]]
    }
    
    func fetchValue(for path: String) -> Any? {
        if path == kSuccess {
            return self.success
        } else {
            return nil
        }
    }
    
    func fetchProvider(for path: String) -> ValueProvider? {
        if path == kSuccess {
            return self.success as? ValueProvider
        } else {
            return nil
        }
    }
}
