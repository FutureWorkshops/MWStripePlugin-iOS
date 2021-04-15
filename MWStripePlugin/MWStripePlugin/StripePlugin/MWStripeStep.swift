//
//  MWStripeStep.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import MobileWorkflowCore

public class MWStripeStep: ORKInstructionStep {
    
    let publishableKey: String
    let ephemeralKeyUrl: String
    let paymentIntentUrl: String
    let customerID: String?
    let productID: String
    let session: Session
    
    init(identifier: String, publishableKey: String, ephemeralKeyUrl: String, paymentIntentUrl: String, customerID: String?, productID: String, session: Session) {
        self.publishableKey = publishableKey
        self.ephemeralKeyUrl = ephemeralKeyUrl
        self.paymentIntentUrl = paymentIntentUrl
        self.customerID = customerID
        self.productID = productID
        self.session = session
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
    public static func build(stepInfo: StepInfo, services: StepServices) throws -> Step {
        guard let publishableKey = stepInfo.data.content["publishableKey"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing required field: publishableKey")
        }
        guard let ephemeralKeyUrl = stepInfo.data.content["ephemeralKeyURL"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing required field: ephemeralKeyURL")
        }
        guard let paymentIntentUrl = stepInfo.data.content["paymentIntentURL"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing required field: paymentIntentUrl")
        }
        guard let productID = stepInfo.data.content["productId"] as? String else {
            throw ParseError.invalidStepData(cause: "Missing required field: productId")
        }
        
        let theStep = MWStripeStep(identifier: stepInfo.data.identifier,
                                publishableKey: publishableKey,
                                ephemeralKeyUrl: ephemeralKeyUrl,
                                paymentIntentUrl: paymentIntentUrl,
                                customerID: stepInfo.data.content["customerId"] as? String, // optional
                                productID: productID,
                                session: stepInfo.session)
        theStep.text = stepInfo.data.content["text"] as? String
        if let image = stepInfo.data.image {
            theStep.image = image
        } else if let urlString = stepInfo.data.imageURL ?? stepInfo.data.content["imageURL"] as? String {
            theStep.image = services.imageLoadingService.syncLoad(image: urlString, session: stepInfo.session)
        }
        return theStep
    }
}
