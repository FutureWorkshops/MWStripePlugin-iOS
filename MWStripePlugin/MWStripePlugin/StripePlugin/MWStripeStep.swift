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
    let ephemeralKeyURL: URL
    let paymentIntentURL: URL
    //TODO: This is just for testing, it should be removed
    let customerID: String
    let productID: String
    
    init(identifier: String, publishableKey: String, ephemeralKeyURL: URL, paymentIntentURL: URL, customerID: String, productID: String) {
        self.publishableKey = publishableKey
        self.ephemeralKeyURL = ephemeralKeyURL
        self.paymentIntentURL = paymentIntentURL
        self.customerID = customerID
        self.productID = productID
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
              let paymentIntentURL = URL(string: paymentIntentURLString),
              let customerID = stepInfo.data.content["customerId"] as? String,
              let productID = stepInfo.data.content["productId"] as? String {
            let step = MWStripeStep(identifier: stepInfo.data.identifier,
                                    publishableKey: publishableKey,
                                    ephemeralKeyURL: ephemeralKeyURL,
                                    paymentIntentURL: paymentIntentURL,
                                    customerID: customerID,
                                    productID: productID)
            step.text = stepInfo.data.content["text"] as? String
            if let image = stepInfo.data.image {
                step.image = image
            } else if let urlString = stepInfo.data.imageURL ?? stepInfo.data.content["imageURL"] as? String {
                step.image = services.imageLoadingService.syncLoad(image: urlString)
            }
            return step
        } else {
            throw ParseError.invalidStepData(cause: "Missing required field from the JSON to build a valid MWStripeStep")
        }
    }
}
