//
//  MWStripePlugin.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import MobileWorkflowCore

public struct MWStripePlugin: Plugin {
    public static var allStepsTypes: [StepType] {
        return MWStripeStepType.allCases
    }
}

public enum MWStripeStepType: String, StepType, CaseIterable {
    
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
