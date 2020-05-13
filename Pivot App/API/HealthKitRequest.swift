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
    var dailySummary: [ActivitySummary] = []

    enum CodingKeys: String, CodingKey {
        case data
        case dailySummary
    }

    init(from data: [Any], and dailySummary: [Any]) {
        self.data = data.compactMap { (object) -> HealthKitData? in
            switch object {
            case let object as HKStatistics:
                return try? SampleData(from: object)
            case let object as HKCategorySample:
                return try? CategoryData(from: object)
            case let object as HKWorkout:
                return try? WorkoutData(from: object)
            default:
                Logger.log(.healthStoreService, info: "Failed to proccess a data!")
                return nil
            }
        }
        self.dailySummary = dailySummary.compactMap { (object) -> ActivitySummary? in
            switch object {
            case let object as HKActivitySummary:
                return ActivitySummary(from: object)
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
            } else if let workout = sample as? WorkoutData {
                try dataContainer.encode(workout)
            }
        }

        var dailyContainer = container.nestedUnkeyedContainer(forKey: .dailySummary)

        try dailySummary.forEach { (summary) in
            try dailyContainer.encode(summary)
        }
    }
}
