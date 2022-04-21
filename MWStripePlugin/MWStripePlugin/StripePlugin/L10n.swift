//
//  L10n.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 11/1/22.
//

import Foundation

extension L10n {

    static func localizedString(key: String) -> String {
        return Bundle(for: MWStripeStep.self).localizedString(forKey: key, value: nil, table: "Localizable")
    }
    
    static let payWithStripe = L10n.localizedString(key: "PAY_WITH_STRIPE")
    static let loading = L10n.localizedString(key: "LOADING")
    static let `continue` = L10n.localizedString(key: "CONTINUE")
    static let processing = L10n.localizedString(key: "PROCESSING")
    static let validating = L10n.localizedString(key: "VALIDATING")
}
