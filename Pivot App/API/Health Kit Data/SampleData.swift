//
//  SampleData.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 2/2/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class SampleData: HealthKitData {
    let quantity: Double
    let unit: String

    init(from sample: HKStatistics) throws {
        let unit = try HealthKitItems.unit(for: sample.quantityType)
        self.unit = unit.unitString

        let type = try HealthKitItems.name(for: sample.quantityType)

        let quantity: HKQuantity
        switch sample.quantityType.aggregationStyle {
        case .cumulative:
            guard let sumQuantity = sample.sumQuantity() else {
                Logger.log(.healthStoreService, warning: "Unable to get Sum for Statistics")
                throw HealthKitRequest.HKRError.noQuantityTypeFound
            }
            quantity = sumQuantity

        case .discrete, .discreteEquivalentContinuousLevel, .discreteArithmetic, .discreteTemporallyWeighted:
            guard let averageQuantity = sample.averageQuantity() else {
                Logger.log(.healthStoreService, warning: "Unable to get Average for Statistics")
                throw HealthKitRequest.HKRError.noQuantityTypeFound
            }
            quantity = averageQuantity

        @unknown default:
            assertionFailure("Unknown aggregation style")
            quantity = HKQuantity(unit: .count(), doubleValue: 0.0)
        }
        self.quantity = quantity.doubleValue(for: unit)

        super.init(from: sample, for: type)

    }

    enum CodingKeys: String, CodingKey {
        case quantity
        case startDate
        case endDate
        case type
        case unit
        case source
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        try container.encode(type, forKey: .type)
        try container.encode(dateFormatter.string(from: startDate), forKey: .startDate)
        try container.encode(dateFormatter.string(from: endDate), forKey: .endDate)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unit, forKey: .unit)
    }
}
