//
//  HealthKitRequest.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/12/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitRequest: Encodable {
    enum HKRError: Error {
        case noQuantityTypeFound
    }

    var data: [HealthKitData] = []

    enum CodingKeys: String, CodingKey {
        case data
    }

    init(from samples: [HKStatistics]) {
        data = samples.compactMap { (sample) -> HealthKitData? in

            return try? SampleData(from: sample)
        }
        Logger.log(.healthStoreService, info: "Finished Processing Data!")
    }

    init(from querySamples: [HKSample]) {
        var index = 0
        var lastPercent: Int = 0
        data = querySamples.compactMap { (sample) -> HealthKitData? in
            let currentPercent: Int = (index / querySamples.count) * 10
            if lastPercent < currentPercent {
                Logger.log(.healthStoreService, verbose: "Processing Data: \(currentPercent)0%...")
                lastPercent = currentPercent
                index += 1
            }
            if let quantitySample = sample as? HKQuantitySample {
                return try? SampleData(from: quantitySample)
            }
            Logger.log(.healthStoreService, info: "Failed to convert to QuantitySample")
            return nil
        }
        Logger.log(.healthStoreService, info: "Finished Processing Data!")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var dataContainer = container.nestedUnkeyedContainer(forKey: .data)
        try data.forEach { (sample) in
            if let sample = sample as? SampleData {
                try dataContainer.encode(sample)
            }
        }
    }
}

class HealthKitData: Encodable {
    let startDate: Date
    let endDate: Date
    let type: String
    let source: String?

    fileprivate init(from sample: HKSample, for type: String, from source: String? = nil) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.type = type
        self.source = source
    }

    fileprivate init(from stat: HKStatistics, for type: String, from source: String? = nil) {
        self.startDate = stat.startDate
        self.endDate = stat.endDate
        self.type = type
        self.source = source
    }
}

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

        case .discrete:
            guard let averageQuantity = sample.averageQuantity() else {
                Logger.log(.healthStoreService, warning: "Unable to get Average for Statistics")
                throw HealthKitRequest.HKRError.noQuantityTypeFound
            }
            quantity = averageQuantity
        }
        self.quantity = quantity.doubleValue(for: unit)

        super.init(from: sample, for: type)

    }

    init(from sample: HKQuantitySample) throws {
        let unit = try HealthKitItems.unit(for: sample.quantityType)
        self.quantity = sample.quantity.doubleValue(for: unit)
        self.unit = unit.unitString

        let type = try HealthKitItems.name(for: sample.quantityType)

        let source = sample.sourceRevision.source.name

        super.init(from: sample, for: type, from: source)
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
        if let source = source {
            try container.encode(source, forKey: .source)
        }
    }
}
