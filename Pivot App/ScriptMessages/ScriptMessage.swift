//
//  ScriptMessage.swift
//  Pivot
//
//  Created by Ryan Schumacher on 12/1/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit

protocol ScriptMessageDelegate: class {
    func onNotificationRegistration(promiseId: Int, value: Bool)
    func onUserAuthenticationReceived(value: String)
    func onEnableAppleHealthKit(promiseId: Int)
    func onReceiveAppleHealthKitTokens(promiseId: Int, tokens: HealthKitTokens)
    func onRequestDeviceInfo(promiseId: Int)

    func onEnableBiometrics(promiseId: Int)
    func onDisableBiometrics(promiseId: Int)

    func onLoadSecureUrl(url: URL)
    func onLoadGoogleFitUrl(url: URL)
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: ScriptMessageDelegate?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            Logger.log(.scriptMessageHandler, warning: "Recieved invalid json from javascript")
            return
        }

        Logger.log(.scriptMessageHandler, info: "Received Script Message: \(body)")

        if let userAuth = body["userGUID"] as? String {
            Logger.log(.scriptMessageHandler, verbose: "Received 'userGUID': \(userAuth)")
            delegate?.onUserAuthenticationReceived(value: userAuth)
        }

        if let bodyValue = body["body"] as? String, let promiseId = body["promiseId"] as? Int {
            Logger.log(.scriptMessageHandler, verbose: "Received Message \(bodyValue) with promiseId:\(promiseId)")

            switch bodyValue {
            case "enablePush":
                delegate?.onNotificationRegistration(promiseId: promiseId, value: true)
            case "disablePush":
                delegate?.onNotificationRegistration(promiseId: promiseId, value: false)
            case "enableBiometric":
                delegate?.onEnableBiometrics(promiseId: promiseId)
            case "disableBiometric":
                delegate?.onDisableBiometrics(promiseId: promiseId)
            case "enableAHK":
                delegate?.onEnableAppleHealthKit(promiseId: promiseId)
            case "receiveAHKtokens":
                if let promiseValue = body["datamationResponse"] as? [String: Any],
                    let tokens = HealthKitTokens(with: promiseValue) {
                    delegate?.onReceiveAppleHealthKitTokens(promiseId: promiseId, tokens: tokens)
                }
            case "deviceInfo":
                delegate?.onRequestDeviceInfo(promiseId: promiseId)

            default:
                Logger.log(.scriptMessageHandler, warning: "Unhandled Body Value \(bodyValue)")
            }
        }

        if let secureString = body["secureUrl"] as? String, let secureUrl = URL(string: secureString) {
            Logger.log(.scriptMessageHandler, verbose: "Received secureURL:\(secureUrl)")
            delegate?.onLoadSecureUrl(url: secureUrl)
        }

        if let secureString = body["googleFitUrl"] as? String, let url = URL(string: secureString) {
            Logger.log(.scriptMessageHandler, verbose: "Received googleFitUrl:\(url)")
            delegate?.onLoadGoogleFitUrl(url: url)
        }
    }
}
