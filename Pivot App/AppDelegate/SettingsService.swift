//
//  SettingsService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 10/17/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit

class SettingsService: NSObject,  ApplicationService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // check that all settings are initiated
        
        // 
        let currentLoginURL = UserDefaults.standard.string(forKey: "login_url")
        if currentLoginURL == nil  || currentLoginURL == "" {
            if let loginURL = Bundle.main.object(forInfoDictionaryKey: "PivotLoginURL") as? String {
                UserDefaults.standard.set(loginURL, forKey: "login_url")
            }
        }
        return true
    }
}
