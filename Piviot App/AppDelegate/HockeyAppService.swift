//
//  HockeyAppService.swift
//  Piviot App
//
//  Created by Ryan Schumacher on 10/15/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit

import HockeySDK

class HockeyAppService: NSObject, ApplicationService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        if let hockeyAppKey = Bundle.main.object(forInfoDictionaryKey: "HockeyAppKey") as? String {
            BITHockeyManager.shared().configure(withIdentifier: hockeyAppKey)
            BITHockeyManager.shared().start()
            BITHockeyManager.shared().authenticator.authenticateInstallation()
        } else {
            print("Failed to find 'HockeyAppKey' in Info.plist.\nSkipping Hockeyapp Initialization.")
        }
        return true
    }
}
