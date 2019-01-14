//
//  HealthKitRefreshTokenResponse.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/13/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation

class HealthKitRefreshTokenResponse: Codable {
    var accessToken: String
    var refreshToken: String
    var dataPath: String
}
