//
//  ViewController+WKDelegates.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 10/21/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications
import SafariServices

extension ViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        debugPrint("Deciding Policy for WebView URL: \(navigationAction.request.url?.absoluteString ?? "No URL Available")")

        let regexPattern: String = "program/.*/programGuide"

        guard
            let url = navigationAction.request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
            else {
                debugPrint("\tAllowing Navigation")
                return decisionHandler(.allow)
        }

        let range = NSRange(location: 0, length: components.path.utf16.count)

        if regex.firstMatch(in: components.path, options: [], range: range) != nil {
            debugPrint("\tCancelling Navigation")
            decisionHandler(.cancel)
            loadFile(url: url)

        } else {
            debugPrint("\tAllowing Navigation")
            decisionHandler(.allow)
        }
    }
}
