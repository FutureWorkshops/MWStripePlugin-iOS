//
//  MWStripeStep.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeStep: ORKStep {
    
    let publishableKey: String
    let ephemeralKeyURL: URL
    let paymentIntentURL: URL
    
    init(identifier: String, publishableKey: String, ephemeralKeyURL: URL, paymentIntentURL: URL) {
        self.publishableKey = publishableKey
        self.ephemeralKeyURL = ephemeralKeyURL
        self.paymentIntentURL = paymentIntentURL
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        return MWStripeViewController.self
    }
}

extension MWStripeStep: MobileWorkflowStep {
    public static func build(step stepInfo: StepInfo, services: MobileWorkflowServices) throws -> ORKStep {
        if let publishableKey = stepInfo.data.content["publishableKey"] as? String,
              let ephemeralKeyURLString = stepInfo.data.content["ephemeralKeyURL"] as? String,
              let ephemeralKeyURL = URL(string: ephemeralKeyURLString),
              let paymentIntentURLString = stepInfo.data.content["paymentIntentURL"] as? String,
              let paymentIntentURL = URL(string: paymentIntentURLString) {
            return MWStripeStep(identifier: stepInfo.data.identifier, publishableKey: publishableKey, ephemeralKeyURL: ephemeralKeyURL, paymentIntentURL: paymentIntentURL)
        } else {
            throw ParseError.invalidStepData(cause: "Missing publishableKey or ephemeralKeyURL")
        }
    }
}
