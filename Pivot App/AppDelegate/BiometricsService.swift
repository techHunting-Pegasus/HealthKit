//
//  BiometricsService.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/17/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit
import LocalAuthentication

class BiometricsService: NSObject, ApplicationService {
    private enum Constants {
        static let isBiometricsEnabledKey = "isBiometricsEnabled_v1"
    }

    static let shared = BiometricsService()
    private let context = LAContext()

    // This value dictates wether or not Biometrics is enabled in the Pivot App.
    // This does not indicate that Biometrics work in the app
    private var isBiometricsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.isBiometricsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.isBiometricsEnabledKey)
        }
    }

    private override init() {
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func onEnableBiometrics(onComplete: @escaping (Bool) -> Void) {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            onComplete(false)
            return
        }

        let reason = "Log in to your app!"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
            [weak self] (success, error) in

            guard success else {
                Logger.log(.biometricsService, warning: "Failed to get authorization for biometrics with error: \(error?.localizedDescription ?? "No Error Found")")

                self?.isBiometricsEnabled = true
                onComplete(false)
                return
            }

            self?.isBiometricsEnabled = true
            onComplete(true)
        }
        
    }

    func onDisableBiometrics(onComplete: @escaping (Bool) -> Void) {
        isBiometricsEnabled = false
        onComplete(true)
    }
}
