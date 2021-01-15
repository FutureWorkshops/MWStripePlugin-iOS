//
//  MWStripeViewController.swift
//  MWStripePlugin
//
//  Created by Xavi Moll on 14/1/21.
//

import Foundation
import Stripe
import MobileWorkflowCore

public class MWStripeViewController: ORKStepViewController {
    
    //MARK: private properties
    private var stripeStep: MWStripeStep { self.step as! MWStripeStep }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        StripeAPI.defaultPublishableKey = self.stripeStep.publishableKey
    }
    
}
