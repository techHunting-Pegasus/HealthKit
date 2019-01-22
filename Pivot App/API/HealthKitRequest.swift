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

    init(from data: [Any]) {
        self.data = data.compactMap { (object) -> HealthKitData? in
            switch object {
            case let object as HKStatistics:
                return try? SampleData(from: object)
            case let object as HKCategorySample:
                return try? CategoryData(from: object)
            default:

                Logger.log(.healthStoreService, info: "Failed to proccess a data!")
                return nil
            }
        }
    }

    init(from samples: [HKStatistics]) {
        data = samples.compactMap { (sample) -> HealthKitData? in

            return try? SampleData(from: sample)
        }
        Logger.log(.healthStoreService, info: "Finished Processing Data!")
    }


    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var dataContainer = container.nestedUnkeyedContainer(forKey: .data)
        try data.forEach { (sample) in
            if let sample = sample as? SampleData {
                try dataContainer.encode(sample)
            } else if let category = sample as? CategoryData {
                try dataContainer.encode(category)
            }
        }
    }
}

class HealthKitData: Encodable {
    let startDate: Date
    let endDate: Date
    let type: String

    fileprivate init(from sample: HKSample, for type: String) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.type = type
    }

    fileprivate init(from stat: HKStatistics, for type: String) {
        self.startDate = stat.startDate
        self.endDate = stat.endDate
        self.type = type
    }
}

class CategoryData: HealthKitData {
    let value: Int

    init(from category: HKCategorySample) throws {

        let type = try HealthKitItems.name(for: category.categoryType)

        self.value = category.value
        super.init(from: category, for: type)
    }

    enum CodingKeys: String, CodingKey {
        case value
        case startDate
        case endDate
        case type
    }

    enum Errors: Error {
        case NoCategoryFound
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

        // Only Supporting Sleep analisys
        guard let categoryValue = HKCategoryValueSleepAnalysis(rawValue: value) else {
            throw Errors.NoCategoryFound
        }
        let sleepValue: String

        switch categoryValue{
        case .asleep: sleepValue = "asleep"
        case .inBed: sleepValue = "inBed"
        case .awake: sleepValue = "awake"
        }

        try container.encode(sleepValue, forKey: .value)
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
