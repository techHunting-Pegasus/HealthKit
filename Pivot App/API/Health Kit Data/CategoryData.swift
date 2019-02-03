//
//  CategoryData.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 2/2/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

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
