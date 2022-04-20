//
//  SceneDelegate.swift
//  MWStripe
//
//  Created by Xavi Moll on 14/1/21.
//  Copyright © 2021 Future Workshops. All rights reserved.
//

import UIKit
import MWStripePlugin
import MobileWorkflowCore

class SceneDelegate: MWSceneDelegate {
    
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        self.dependencies.plugins = [
            MWStripePluginStruct.self
        ]
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
