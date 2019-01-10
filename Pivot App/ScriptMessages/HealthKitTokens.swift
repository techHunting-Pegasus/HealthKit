//
//  HealthKitTokens.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/9/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation

struct HealthKitTokens {
    let refreshToken: String
    let accessToken: String
    let dataMationID: String

    init?(with dict: [String: Any]) {
        guard
            let refreshToken = dict["refreshToken"] as? String,
            let accessToken = dict["accessToken"] as? String,
            let dataMationID = dict["dataMationID"] as? String
            else {
                return nil
        }
        self.refreshToken = refreshToken
        self.accessToken = accessToken
        self.dataMationID = dataMationID
    }
}
