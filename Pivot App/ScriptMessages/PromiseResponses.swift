//
//  PromiseResponses.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/8/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit
import LocalAuthentication

struct PushResponse: Encodable {
    enum BiometricType: String, Encodable {
        case faceId
        case fingerprint
    }
    let deviceType: String = "ios"
    var deviceUniqueId: String?

    var deviceModel: String
    var deviceOS: String
    var deviceAppVersion: String

    var deviceId: String?
    var devicePushEnabled: Bool

    var deviceBiometricAvailable: Bool
    var biometricType: BiometricType?

    init(deviceId: String?, context: LAContext) {
        self.deviceId = deviceId
        self.devicePushEnabled = deviceId != nil

        self.deviceUniqueId = UniqueDeviceIdService.shared.id

        self.deviceModel = PushResponse.getDeviceModel()
        self.deviceOS = PushResponse.getDeviceOS()
        self.deviceAppVersion = PushResponse.getDeviceAppVersion()

        var error: NSError?
        if #available(iOS 11.0, *), context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {

            switch context.biometryType {
            case .faceID:
                biometricType = .faceId
                deviceBiometricAvailable = true
            case .touchID:
                biometricType = .fingerprint
                deviceBiometricAvailable = true
            default:
                biometricType = nil
                deviceBiometricAvailable = false
            }
        } else {
            // Fallback on earlier versions
            biometricType = nil
            deviceBiometricAvailable = false
        }
    }
}

extension PushResponse {

    private static func getDeviceOS() -> String {
        return UIDevice.current.systemVersion
    }

    private static func getDeviceModel() -> String {
        return UIDevice.current.modelName
    }

    private static func getDeviceAppVersion() -> String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }

}
