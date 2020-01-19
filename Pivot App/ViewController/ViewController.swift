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
import HealthKit

let CallbackNotification = Notification.Name(rawValue: "CallbackNotification")
let CallbackNotificationURLKey = "URL"

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    var docController: UIDocumentInteractionController?

    private var currentPromiseId: Int?
    var hasCompletedFirstNavigation = false

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

        let webView = WKWebView(frame: CGRect(origin: CGPoint(x:0,y:20), size: .zero), configuration: webConfiguration)
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

        if let websiteUrl = UserDefaults.standard.string(forKey: Constants.loginUrl) {
            guard let requestUrl = URL(string: websiteUrl) else { return }
            loadURL(url: requestUrl)
        }
        UserDefaults.standard.addObserver(self, forKeyPath: Constants.loginUrl,
                                          options: .new,
                                          context: nil)

        UserDefaults.standard.addObserver(self, forKeyPath: Constants.tokenKey,
                                          options: .new,
                                          context: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onCallbackNotification),
                                               name: CallbackNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }

    func dismissSafariVC() {
        self.dismiss(animated: true)
    }

    func presentWebView(for url: URL) {
        DispatchQueue.main.async {
            let viewController = SFSafariViewController(url: url)
            viewController.delegate = self
            self.present(viewController, animated: true)
        }
    }

    override func observeValue(forKeyPath _keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let keyPath = _keyPath else { return }
        switch keyPath {
        case Constants.loginUrl:
            // Load the URL on the main thread 
            DispatchQueue.main.async { [weak self] in
                if let szUrl = change?[.newKey] as? String,
                    let url = URL(string: szUrl) {
                    self?.loadURL(url: url)
                }
            }
        case Constants.tokenKey:
            DispatchQueue.main.async { [weak self] in
                if let token = change?[.newKey] as? String,
                    let promiseId = self?.currentPromiseId {
                    self?.fulfillPromise(promiseId: promiseId, with: token)
                }
            }
        default: break
        }
    }

    private func fulfillPromise(promiseId: Int, with token: String? = nil) {
        Logger.log(.viewController, info: "Fulfilling Promise with ID: \(promiseId) and Token: \(token ?? "No Token")")
        var javaScript = "window.resolvePromise(" + String(promiseId)
        if let token = token {
            javaScript += ", \"\(token)\")"
        } else {
            javaScript += ")"
        }
        webView?.evaluateJavaScript(javaScript, completionHandler: nil)
    }
}

extension ViewController: ScriptMessageDelegate {

    func onUserAuthenticationReceived(value: String) {
        UserDefaults.standard.set(value, forKey: Constants.userAuthorization)
    }

    func onNotificationRegistration(promiseId: Int, value: Bool) {
        if let deviceToken = UserDefaults.standard.string(forKey: Constants.tokenKey) {
            // we are registered for notifications.
            fulfillPromise(promiseId: promiseId, with: deviceToken)
        }
        guard value == true else {
            fulfillPromise(promiseId: promiseId)
            return
        }
        currentPromiseId = promiseId
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] (granted, _) in
                // Enable or disable features based on authorization.
                DispatchQueue.main.async {
                    guard granted == true else {
                        self?.fulfillPromise(promiseId: promiseId)
                        return
                    }
                    #if targetEnvironment(simulator)
                    self?.fulfillPromise(promiseId: promiseId)
                    #else
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    func onEnableAppleHealthKit(promiseId: Int) {
        if HKHealthStore.isHealthDataAvailable() {
            HealthKitService.instance.requestAuthorization { [weak self] (success) in
                DispatchQueue.main.async { [weak self] in
                    self?.fulfillPromise(promiseId: promiseId, with: success.description)
                }
            }
        }
    }
    func onReceiveAppleHealthKitTokens(promiseId: Int, tokens: HealthKitTokens) {
        HealthKitService.instance.storeTokens(tokens)
        HealthKitService.instance.fetchAllStatisticsData()
        self.fulfillPromise(promiseId: promiseId)
    }

    func onLoadSecureUrl(url: URL) {
        print("Loading Secure URL:\(String(describing: url))")
        DispatchQueue.main.async {
            let viewController = SFSafariViewController(url: url)
            viewController.delegate = self
            self.present(viewController, animated: true)
        }
    }

    func onLoadGoogleFitUrl(url: URL) {
        print("Loading Google Fit URL:\(String(describing: url))")
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

        Analytics.track(event: .openDeepLink(url))
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

// - Tracking
extension ViewController {
    
    
    @available(iOS 11.0, *)
    func fetchValidAuthJWT(completion: @escaping (PivotJWT?) -> Void) {
        DispatchQueue.main.async {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies {
                var result: PivotJWT?
                if let authCookie = $0.first(where: { $0.name == "pivot_jwt" }), authCookie.isExpired == false {
                    // Check if cookie containing JWT is expired
                    Logger.log(.viewController, verbose: "Found valid JWT Cookie")
                    if let pivotJWT = try? PivotJWT(jwt: authCookie.value), pivotJWT.isExpired == false {
                        Logger.log(.viewController, verbose: "Found valid PivotJWT")
                        // Valid PivotJWT found, return result
                        result = pivotJWT
                    } else {
                        Logger.log(.viewController, verbose: "Failed to find valid PivotJWT")
                    }
                } else {
                    Logger.log(.viewController, verbose: "Failed to find valid JWT Cookie")
                }
                completion(result)
            }
        }
    }
    @available(iOS 11.0, *)
    func trackAppVisit() {
        fetchValidAuthJWT { _jwt in
            guard
                let jwt = _jwt,
                let request = try? PivotAPI.trackAppVisit(authToken: jwt.jwt).request()
            else { return }
            
            URLSession.shared.dataTask(with: request).resume()
        }
    }
    @objc func applicationWillEnterForeground(noti: NSNotification) {
        if #available(iOS 11.0, *) {
            trackAppVisit()
        }
    }
}

extension HTTPCookie {
    /**
    	Returnes the Expired State of the cookie
     - True is expired
     - False is not expired
     - nil if no expiration date is found.
     */
    var isExpired: Bool? {
        guard let expiresDate = self.expiresDate else { return nil }
        let now = Date()
        return now.compare(expiresDate) == .orderedDescending
    }
}
