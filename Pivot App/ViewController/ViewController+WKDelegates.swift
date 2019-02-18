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

        guard regex.firstMatch(in: components.path, options: [], range: range) == nil else {
            debugPrint("\tCancelling Navigation")
            decisionHandler(.cancel)
            loadFile(url: url)
            return

        }
        guard let oldURLHost = webView.url?.host, oldURLHost == url.host else {
            debugPrint("\tNavigating to external host")
            decisionHandler(.cancel)
            presentWebView(for: url)
            return
        }

        debugPrint("\tAllowing Navigation")
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        guard
            let newURLHost = elementInfo.linkURL?.host,
            let oldURLHost = webView.url?.host,
            oldURLHost != newURLHost
        else { return false }

        return true
    }

    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {

        guard let url = elementInfo.linkURL else { return nil }

        let viewController = SFSafariViewController(url: url)
        viewController.delegate = self

        return viewController

    }

    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {

        guard let sfWebView = previewingViewController as? SFSafariViewController else { return }

        self.present(sfWebView, animated: true)
    }
}
