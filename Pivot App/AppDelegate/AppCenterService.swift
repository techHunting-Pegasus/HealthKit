//
//  AppCenterService.swift
//  Pivot App
//
//  Created by Ryan Schumacher on 10/15/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute

class AppCenterService: NSObject, ApplicationService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        if let appCenterKey = Bundle.main.object(forInfoDictionaryKey: "AppCenterKey") as? String {
            #if DEBUG
            MSAppCenter.start(appCenterKey, withServices: [MSAnalytics.self, MSCrashes.self])
            #else
            MSAppCenter.start(appCenterKey, withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self])
            #endif
        } else {
            print("'AppCenterKey' not found in Info.plist.\nSkipping App Center Initialization.")
        }
        return true
    }
}
