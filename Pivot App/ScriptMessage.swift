//
//  ScriptMessage.swift
//  Pivot
//
//  Created by Ryan Schumacher on 12/1/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit

protocol NotificationScriptMessageDelegate: class {
    func onNotificationRegistration(promiseId: Int, value: Bool)
    func onUserAuthenticationReceived(value: String)
    
    func onLoadSecureUrl(url: URL)
    func onLoadFitbitUrl(url: URL)
}

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: NotificationScriptMessageDelegate?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            print("Recieved invalid json from javascript")
            return
        }
        if let userAuth = body["userGUID"] as? String {
            delegate?.onUserAuthenticationReceived(value: userAuth)
        }
        
        if let bodyValue = body["body"] as? String, let promiseId = body["promiseId"] as? Int {
            switch bodyValue {
            case "enablePush":
                delegate?.onNotificationRegistration(promiseId: promiseId, value: true)
            case "disablePush":
                delegate?.onNotificationRegistration(promiseId: promiseId, value: false)
            default: break
            }
        }
        
        if let secureString = body["secureUrl"] as? String, let secureUrl = URL(string: secureString){
            delegate?.onLoadSecureUrl(url: secureUrl)
        }
        
        if let secureString = body["googleFitUrl"] as? String, let url = URL(string: secureString){
            delegate?.onLoadFitbitUrl(url: url)
        }

    }
}
