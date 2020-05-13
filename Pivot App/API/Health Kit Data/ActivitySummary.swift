//
//  ActivitySummary.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 12/26/20.
//  Copyright © 2021 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class ActivitySummary: Encodable {
    let date: Date

    let moveTime: TimeInterval?
    let exerciseTime: TimeInterval?

    let activeEnergyBurned: Double?
    let activeEnergyUnit: String?

    enum CodingKeys: CodingKey {
        case date
        case moveTime
        case exerciseTime

        case activeEnergyBurned
        case activeEnergyUnit
    }

    init?(from data: HKActivitySummary) {
        guard let date = data.dateComponents(for: .current).date else { return nil}
        self.date = date

        let activeEnergyUnit = HKUnit.kilocalorie()
        self.activeEnergyBurned = data.activeEnergyBurned.doubleValue(for: activeEnergyUnit)
        self.activeEnergyUnit = activeEnergyUnit.unitString

        if #available(iOS 14.0, *) {
            self.moveTime = data.appleMoveTime.doubleValue(for: .second())
        } else {
            self.moveTime = nil
        }

        self.exerciseTime = data.appleExerciseTime.doubleValue(for: .second())
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        try container.encode(dateFormatter.string(from: date),
                             forKey: .date)

        try container.encode(moveTime, forKey: .moveTime)
        try container.encode(exerciseTime, forKey: .exerciseTime)

        if let activeEnergyBurned = self.activeEnergyBurned,
           let activeEnergyUnit = self.activeEnergyUnit {

            try container.encode(activeEnergyBurned, forKey: .activeEnergyBurned)
            try container.encode(activeEnergyUnit, forKey: .activeEnergyUnit)
        }
    }
}
