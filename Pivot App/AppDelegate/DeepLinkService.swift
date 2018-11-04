//
//  DeepLinkService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 1/21/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit

class DeepLinkService: NSObject, ApplicationService {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        debugPrint("DeepLinkService: Opening from URL:\(url.absoluteString)")
        if let sourceApp = options[.sourceApplication],
            String(describing: sourceApp) == "com.apple.SafariViewService" {
            NotificationCenter.default.post(name: CallbackNotification,
                                            object: nil,
                                            userInfo: [CallbackNotificationURLKey: url])
        }
        return true
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL
        else {
                return false
        }
        
        debugPrint("DeepLinkService: Continuing from Universal Link:\(incomingURL)")
        
        NotificationCenter.default.post(name: CallbackNotification,
                                        object: nil,
                                        userInfo: [CallbackNotificationURLKey: incomingURL])

        return true
    }
}
