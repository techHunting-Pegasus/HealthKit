//
//  DeepLinkService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 1/21/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit

class DeepLinkService: NSObject, ApplicationService {
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return true
    }
}
