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
    func onMessage()
}

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: NotificationScriptMessageDelegate?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        delegate?.onMessage()
    }
}
