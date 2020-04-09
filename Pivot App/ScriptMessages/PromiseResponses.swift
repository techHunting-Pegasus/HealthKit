//
//  PromiseResponses.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/8/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import Foundation
import LocalAuthentication

struct EnablePushResponse: Encodable {
    enum BiometricType: String, Encodable {
        case faceId
        case fingerprint
    }
    var deviceId: String?
    var shouldPromptBiometrics: Bool
    var biometricType: BiometricType?

    init(deviceId: String?, context: LAContext) {
        self.deviceId = deviceId

        var error: NSError?
        if #available(iOS 11.0, *), context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {

            switch context.biometryType {
            case .faceID:
                biometricType = .faceId
                shouldPromptBiometrics = true
            case .touchID:
                biometricType = .fingerprint
                shouldPromptBiometrics = true
            default:
                biometricType = nil
                shouldPromptBiometrics = false
            }
        } else {
            // Fallback on earlier versions
            biometricType = nil
            shouldPromptBiometrics = false
        }
    }
}
