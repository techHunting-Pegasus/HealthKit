//
//  PivotAPIRequestData.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation

extension PivotAPI {
    
    static func formattedVersion() -> String {
        return "iOS Version \(Util.appVersion())"
    }

    struct RegisterDeviceRequest: Encodable {
        var type: String { return PivotAPI.formattedVersion() }
        let token: String
        let uniqueIdentifier: String
    }

}
