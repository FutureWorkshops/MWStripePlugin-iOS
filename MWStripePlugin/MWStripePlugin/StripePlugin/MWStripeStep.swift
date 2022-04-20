//
//  MWStripeStep.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeStep: MWStep {
    
    public let session: Session
    public let services: StepServices
    public let contentURL: String
    public let paymentIntentURL: String
    
    init(identifier: String, session: Session, services: StepServices, contentURL: String, paymentIntentURL: String) {
        self.session = session
        self.services = services
        self.contentURL = contentURL
        self.paymentIntentURL = paymentIntentURL
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func instantiateViewController() -> StepViewController {
        MWStripeViewController(step: self)
    }
}

extension MWStripeStep: BuildableStep {
    
    public static var mandatoryCodingPaths: [CodingKey] {
        ["url", "payment_intent_url"]
    }
    
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        guard let contentURL = stepInfo.data.content["url"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing content URL")
        }
        
        guard let paymentIntentURL = stepInfo.data.content["payment_intent_url"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing payment intent URL")
        }
        
        let step = MWStripeStep(identifier: stepInfo.data.identifier, session: stepInfo.session, services: services, contentURL: contentURL, paymentIntentURL: paymentIntentURL)
        step.text = stepInfo.data.content["text"] as? String
        
        return step
    }
}
