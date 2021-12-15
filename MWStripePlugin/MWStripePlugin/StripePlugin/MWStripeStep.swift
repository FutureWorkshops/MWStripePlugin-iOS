//
//  MWStripeStep.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeStep: MWStep, InstructionStep {
    
    public let session: Session
    public let services: StepServices
    public var imageURL: String? = nil //FIXME: Add it later on depending on the UI that we need
    public var image: UIImage? = nil //FIXME: Add it later on depending on the UI that we need
    public let configurationURLString: String
    
    init(identifier: String, session: Session, services: StepServices, configurationURLString: String) {
        self.session = session
        self.services = services
        self.configurationURLString = configurationURLString
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func instantiateViewController() -> StepViewController {
        MWStripeViewController(instructionStep: self)
    }
}

extension MWStripeStep: BuildableStep {
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        guard let configurationURLString = stepInfo.data.content["payment_intent_url"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing configuration URL")
        }
        
        let step = MWStripeStep(identifier: stepInfo.data.identifier, session: stepInfo.session, services: services, configurationURLString: configurationURLString)
        step.text = stepInfo.data.content["text"] as? String
        
        return step
    }
}
