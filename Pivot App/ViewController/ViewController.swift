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
import SafariServices

let CallbackNotification = Notification.Name(rawValue: "CallbackNotification")
let CallbackNotificationURLKey = "URL"

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    var docController: UIDocumentInteractionController?
    
    private var currentPromiseId: Int? = nil
    
    override func loadView() {
        self.view = UIView()
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.white

        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let messageHandler = ScriptMessageHandler()
        messageHandler.delegate = self
        
        userContentController.add(messageHandler, name: "observer")
        webConfiguration.userContentController = userContentController

        let webView = WKWebView(frame: CGRect(origin:CGPoint(x:0,y:20), size: .zero), configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.webView = webView
        self.view.addSubview(webView)

        // Update constraints
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0).isActive = true

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let websiteUrl = UserDefaults.standard.string(forKey: "login_url") {
            guard let requestUrl = URL(string: websiteUrl) else { return }
            loadURL(url: requestUrl)
        }
        
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.login_url,
                                          options: .new,
                                          context: nil)
        
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.token_key,
                                          options: .new,
                                          context: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onCallbackNotification),
                                               name: CallbackNotification,
                                               object: nil)
    }
    
    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    func dismissSafariVC() {
        self.dismiss(animated: true)
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


extension ViewController: ScriptMessageDelegate {
    
    func onUserAuthenticationReceived(value: String) {
        UserDefaults.standard.set(value, forKey: Constants.user_authorization)
    }
    
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
    
    func onLoadSecureUrl(url: URL) {
        print("Loading Secure URL:\(String(describing:url))")
        DispatchQueue.main.async {
            let viewController = SFSafariViewController(url: url)
            viewController.delegate = self
            self.present(viewController, animated: true)
        }
    }
    
    func onLoadGoogleFitUrl(url: URL) {
        print("Loading Google Fit URL:\(String(describing:url))")
        DispatchQueue.main.async {
            UIApplication.shared.openURL(url)
            
        }
    }
    
    @objc func onCallbackNotification(notification: Notification) {
        defer { self.dismissSafariVC() }
        
        guard
            let callbackURL = notification.userInfo?[CallbackNotificationURLKey] as? URL,
            var components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        else {
            print("Failed to build Callback URL")
            return
        }
        
        if components.scheme != "https" {
            components.scheme = "https"
        }
        
        guard let url = components.url else {
            print("Failed to construct URL from Components")
            return
        }
        
        print("Callback Notification with URL:\(url)")
        
        let request = URLRequest(url: url)

        self.webView.load(request)
    }
}

extension ViewController: SFSafariViewControllerDelegate {
    
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        DispatchQueue.main.async {
        }
    }
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        DispatchQueue.main.async {
            self.dismissSafariVC()
        }
    }

}

