//
//  MWStripePlugin.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import MobileWorkflowCore

public struct MWStripePlugin: MobileWorkflowPlugin {
    public static var allStepsTypes: [MobileWorkflowStepType] {
        return MWStripeStepType.allCases
    }
}

public enum MWStripeStepType: String, MobileWorkflowStepType, CaseIterable {
    
    case basicCheckout = "com.stripe.StripeBasicCheckout"
    
    public var typeName: String {
        return self.rawValue
    }
    
    public var stepClass: MobileWorkflowStep.Type {
        switch self {
        case .basicCheckout: return MWStripeStep.self
        }
    }
}
