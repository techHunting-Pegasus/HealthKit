//
//  WorkoutData.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 2/2/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutData: HealthKitData {
    let duration: TimeInterval
    let activityType: String

    let totalDistance: Double?
    let distanceUnit: String?

    let totalEnergyBurned: Double?
    let energyBurnedUnit: String?

    init(from workout: HKWorkout) throws {
        self.duration = workout.duration
        self.activityType = HealthKitWorkouts.name(for: workout.workoutActivityType)

        if let distanceQuantity = workout.totalDistance {
            let unit = HKUnit.meter()

            self.totalDistance = distanceQuantity.doubleValue(for: unit)
            self.distanceUnit = unit.unitString
        } else {
            self.totalDistance = nil
            self.distanceUnit = nil
        }

        if let energyBurnedQuantity = workout.totalEnergyBurned {
            let unit = HKUnit.kilocalorie()

            self.totalEnergyBurned = energyBurnedQuantity.doubleValue(for: unit)
            self.energyBurnedUnit = unit.unitString
        } else {
            self.totalEnergyBurned = nil
            self.energyBurnedUnit = nil
        }

        super.init(from: workout, for: "workout")
    }

    enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
        case type

        case duration
        case activityType

        case totalDistance
        case distanceUnit

        case totalEnergyBurned
        case energyBurnedUnit
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        try container.encode(type, forKey: .type)
        try container.encode(dateFormatter.string(from: startDate),
                             forKey: .startDate)
        try container.encode(dateFormatter.string(from: endDate),
                             forKey: .endDate)

        try container.encode(duration, forKey: .duration)
        try container.encode(activityType, forKey: .activityType)

        if let totalDistance = self.totalDistance,
            let distanceUnit = self.distanceUnit {
            try container.encode(totalDistance, forKey: .totalDistance)
            try container.encode(distanceUnit, forKey: .distanceUnit)
        }

        if let totalEnergyBurned = self.totalEnergyBurned,
            let energyBurnedUnit = self.energyBurnedUnit {
            try container.encode(totalEnergyBurned,
                                 forKey: .totalEnergyBurned)
            try container.encode(energyBurnedUnit,
                                 forKey: .energyBurnedUnit)
        }
    }
}
