//
//  DeviceInfo.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 3/23/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit

struct DeviceInfo: Encodable {
    let appVersion: String
    let deviceType: String = "iOS"
    let deviceModel: String
    let deviceOSVersion: String

    init() {
        self.appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        self.deviceModel = UIDevice.current.modelName
        self.deviceOSVersion = UIDevice.current.systemVersion
    }
}
