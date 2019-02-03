//
//  HealthKitData.swift
//  GoPivot
//
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitData: Encodable {
    let startDate: Date
    let endDate: Date
    let type: String

    init(from sample: HKSample, for type: String) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.type = type
    }

    init(from stat: HKStatistics, for type: String) {
        self.startDate = stat.startDate
        self.endDate = stat.endDate
        self.type = type
    }
}
