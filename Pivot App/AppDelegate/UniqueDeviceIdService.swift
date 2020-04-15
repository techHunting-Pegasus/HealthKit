//
//  UniqueDeviceIdService.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/14/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit

class UniqueDeviceIdService: NSObject, ApplicationService {

    static let shared = UniqueDeviceIdService()

    let id: String

    private override init() {
        if let uid = UserDefaults.standard.string(forKey: "UniqueDeviceIdService") {
            self.id = uid
        } else {
            let uid = UUID().uuidString
            UserDefaults.standard.set(uid, forKey: "UniqueDeviceIdService")
            self.id = uid
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        return true
    }
}
