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
    func onNotificationRegistration(value: Bool)
    func onUserGUIDRecieved(value: String)
}

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: NotificationScriptMessageDelegate?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            print("Recieved invalid json from javascript")
            return
        }
        // check for guid first
        if let guid = body["userGUID"] as? String {
            delegate?.onUserGUIDRecieved(value: guid)
        }
        
        if let bodyValue = body["body"] as? String {
            switch bodyValue {
            case "enablePush":
                delegate?.onNotificationRegistration(value: true)
            case "disablePush":
                delegate?.onNotificationRegistration(value: false)
            default: break
            }
        }

    }
}
