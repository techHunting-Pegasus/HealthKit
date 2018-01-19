//
//  ViewController.swift
//  Pivot App
//
//  Created by Ryan Schumacher on 10/4/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private var currentPromiseId: Int? = nil
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let messageHandler = NotificationScriptMessageHandler()
        messageHandler.delegate = self
        
        userContentController.add(messageHandler, name: "observer")
        webConfiguration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        self.webView = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let websiteUrl = UserDefaults.standard.string(forKey: "login_url") {
            guard let requestUrl = URL(string: websiteUrl) else { return }
            loadURL(url: requestUrl)
        }
        
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.login_url, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.token_key, options: .new, context: nil)
    }
    
    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }

    override func observeValue(forKeyPath _keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let keyPath = _keyPath else { return }
        switch keyPath {
        case Constants.login_url:
            // Load the URL on the main thread 
            DispatchQueue.main.async { [weak self] in
                if let szUrl = change?[.newKey] as? String,
                    let url = URL(string: szUrl) {
                    self?.loadURL(url: url)
                }
            }
        case Constants.token_key:
            DispatchQueue.main.async { [weak self] in
                if let token = change?[.newKey] as? String,
                    let promiseId = self?.currentPromiseId {
                    self?.fulfillTokenPromise(promiseId: promiseId, token: token)
                }
            }
        default: break
        }
    }
    
    private func fulfillTokenPromise(promiseId: Int, token: String) {
        let javaScript = "window.resolvePromise(" + String(promiseId) + ", \"\(token)\")"
        webView?.evaluateJavaScript(javaScript, completionHandler: nil)
    }
}

extension ViewController: WKUIDelegate {
}

extension ViewController: NotificationScriptMessageDelegate {
    
    func onNotificationRegistration(promiseId: Int, value: Bool) {
        if let deviceToken = UserDefaults.standard.string(forKey: Constants.token_key) {
            // we are registered for notifications.
            fulfillTokenPromise(promiseId: promiseId, token: deviceToken)
        }
        guard value == true else { return }
        currentPromiseId = promiseId
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                // Enable or disable features based on authorization.
                guard granted == true else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

