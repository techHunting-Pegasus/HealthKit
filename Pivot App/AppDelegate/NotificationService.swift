//
//  NotificationService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 12/6/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit

class NotificationService: NSObject, ApplicationService {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        
        UserDefaults.standard.set(token, forKey: Constants.token_key)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

}
