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
        guard
            let userGUID = UserDefaults.standard.value(forKey: "userGUID") as? String else {
            return
        }
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        if let request = try? PivotAPI.registerDevice(token: token, guid: userGUID).request() {
            URLSession.shared.dataTask(with: request)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

}
