//
//  BiometricsService.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/17/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit
import LocalAuthentication
import WebKit

class BiometricsService: NSObject, ApplicationService {
    private enum Constants {
        static let isBiometricsEnabledKey = "isBiometricsEnabled_v1"
        static let lastAppDismissedKey = "lastAppDismissed_v1"
        static let biometricLoginTimeoutKey = "BiometricLoginTimeout"
        static let pivotCookieKey = "PivotCookie_v1"

        static let pivotCookieName = "pivot_jwt"
    }

    static let shared = BiometricsService()
    private let context = LAContext()
    private var popupWindow: UIWindow?

    // This value dictates wether or not Biometrics is enabled in the Pivot App.
    // This does not indicate that Biometrics work in the app
    private(set) var isBiometricsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.isBiometricsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.isBiometricsEnabledKey)
        }
    }

    private var lastAppDismiss: Date? {
        get {
            return UserDefaults.standard.object(forKey: Constants.lastAppDismissedKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.lastAppDismissedKey)
        }
    }

    private override init() {
        super.init()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func challengeLogin() {
        var error: NSError?
        guard #available(iOS 11.0, *), context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available before iOS 11
            Logger.log(.biometricsService, info: "Biometrics service not available")
            return
        }

        guard isBiometricsEnabled else {
            Logger.log(.biometricsService, info: "Biometrics not currently enabled.")
            return
        }

        guard let lastAppDismiss = lastAppDismiss,
            let timeout = Bundle.main.object(forInfoDictionaryKey: Constants.biometricLoginTimeoutKey) as? NSNumber else {
                Logger.log(.biometricsService, info: "Required Biometrics Metadata not found")
                return
        }

        Logger.log(.biometricsService, info: "Last App Dismissed: \(lastAppDismiss) and timeout: \(timeout)")

        guard lastAppDismiss.addingTimeInterval(timeout.doubleValue).compare(Date()) == .orderedAscending else {
            Logger.log(.biometricsService, info: "Not Enough time has elapsed, cancelling biometrics")
            return
        }

        // We need to show biometrics
        Logger.log(.biometricsService, info: "Timeout has elapsed. We need to see if we can show biometrics")


        fetchValidPivotCookie { (_pivotCookie) in

            guard let pivotCookie = _pivotCookie else {
                Logger.log(.biometricsService, info: "Cookie Expired or Not Found")
                return
            }

            Logger.log(.biometricsService, info: "Cookie found: \(pivotCookie.description)")

            DispatchQueue.main.async {
                self.presentBlurOverlay()

                let reason = "Log in to your app!"

                self.context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    [weak self] (success, error) in

                    DispatchQueue.main.async {
                        self?.dismissBlurOverlay()
                        guard success == false else {
                            Logger.log(.biometricsService, info: "We have successfully logged in!")
                            return
                        }

                        Logger.log(.biometricsService, info: "Biometrics Failed. Logging user out!")
                        self?.clear(cookie: pivotCookie)

                        NotificationCenter.default.post(name: LogoutNotification, object: nil)
                    }
                }
            }
        }
    }

    private var shouldChallengeLogin: Bool = true

    func applicationDidEnterBackground(_ application: UIApplication) {
        lastAppDismiss = Date()
        shouldChallengeLogin = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if shouldChallengeLogin == true {
            challengeLogin()
            shouldChallengeLogin = false
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func onEnableBiometrics(onComplete: @escaping (Bool) -> Void) {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // TODO: Show message to user to check setting to enable biometrics
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

    func presentBlurOverlay() {
        if let keyWindow = UIApplication.shared.keyWindow {
            let newWindow = UIWindow(frame: keyWindow.frame)
            newWindow.windowLevel = .alert

            newWindow.rootViewController = BlurViewController(nibName: nil, bundle: nil)
            newWindow.makeKeyAndVisible()

            popupWindow = newWindow
        }
    }

    func dismissBlurOverlay() {

        popupWindow = nil
    }
}

@available(iOS 11.0, *)
extension BiometricsService {
    fileprivate func fetchValidPivotCookie(onComplete: @escaping (HTTPCookie?) -> Void) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            let pivotCookie = cookies.first { (cookie) -> Bool in
                cookie.name == Constants.pivotCookieName
            }

            guard pivotCookie?.isExpired == false else {
                return onComplete(nil)
            }
            onComplete(pivotCookie)
        }
    }

    fileprivate func clear(cookie: HTTPCookie, onComplete: (() -> Void)? = nil) {
        WKWebsiteDataStore.default().httpCookieStore.delete(cookie, completionHandler: onComplete)
    }
}
