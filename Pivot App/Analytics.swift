//
//  Analytics.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/9/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import AppCenterAnalytics

class Analytics {

    enum Events {
        case login
        case healthKitEnabled
        case healthKitDataUploadSucceeded(Int)
        case healthKitDataUploadFailed(Error, Int)
        case openDeepLink(URL)
    }


    static func track(event: Analytics.Events) {
        switch event {
        case .login:
            MSAnalytics.trackEvent("Login")
        case .healthKitEnabled:
            MSAnalytics.trackEvent("HealthKitEnabled")
        case .openDeepLink(let url):
            if let cleanUrl = Analytics.clean(url: url) {
                MSAnalytics.trackEvent("OpenDeepLink", withProperties: ["url": cleanUrl])
            }
        case .healthKitDataUploadSucceeded(let count):
            MSAnalytics.trackEvent("HealthKitDataUploadSucceeded",
                                   withProperties: ["dataCount":"\(count)"])
        case .healthKitDataUploadFailed(let error, let count):
            MSAnalytics.trackEvent("HealthKitDataUploadFailed",
                                   withProperties: ["dataCount":"\(count)",
                                    "error":"\(error.localizedDescription)"])
        }
    }

    private init() {}

    private static func clean(url: URL) -> String? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.query = nil
        return components.url?.absoluteString
    }
}
