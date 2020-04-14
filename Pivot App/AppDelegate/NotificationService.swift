//
//  NotificationService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 12/6/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit

class NotificationService: NSObject, ApplicationService {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }

        let newToken = tokenParts.joined()
        if let oldToken = UserDefaults.standard.string(forKey: Constants.tokenKey),
            let refreshToken = UserDefaults.standard.string(forKey: Constants.refreshToken),
            let request = try? PivotAPI.refreshDevice(oldToken: oldToken, refreshToken: refreshToken).request() {
            URLSession.shared.dataTask(with: request)
        }

        UserDefaults.standard.set(newToken, forKey: Constants.tokenKey)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        defer {
            completionHandler(.noData)
        }

        guard let data = userInfo["data"] as? [AnyHashable: Any] else { return }
        guard let link = data["link"] as? String else { return }
        guard let url = URL(string: link) else { return }

        NotificationCenter.default.post(name: CallbackNotification,
                                        object: nil,
                                        userInfo: [CallbackNotificationURLKey: url])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

}
