//
//  HealthKitItem.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/16/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

struct HealthKitItem {
    let unit: HKUnit
    let name: String

    fileprivate init(_ name: String, unit: HKUnit) {
        self.unit = unit
        self.name = name
    }
}

class HealthKitItems {
    enum HKIError: Error {
        case noNameFound
        case noUnitFound
    }
    private init() {}

    static var quantityTypeIdentifiers: [HKQuantityTypeIdentifier] {
        return Array(items.keys)
    }

    static var categoryTypeIdentifiers: [HKCategoryTypeIdentifier] {
        return Array(categoryItems.keys)
    }

    static func name(for type: HKQuantityType) throws -> String {
        return try name(for: HKQuantityTypeIdentifier(rawValue: type.identifier))
    }

    static func name(for type: HKCategoryType) throws -> String {
        return try name(for: HKCategoryTypeIdentifier(rawValue: type.identifier))
    }

    static func name(for identifier: HKQuantityTypeIdentifier) throws -> String {
        guard let name = items[identifier]?.name else {
            throw HKIError.noNameFound
        }
        return name
    }

    static func name(for identifier: HKCategoryTypeIdentifier) throws -> String {
        guard let name = categoryItems[identifier]?.name else {
            throw HKIError.noNameFound
        }
        return name
    }

    static func unit(for type: HKQuantityType) throws -> HKUnit {
        return try unit(for: HKQuantityTypeIdentifier(rawValue: type.identifier))
    }

    static func unit(for type: HKCategoryType) throws -> HKUnit {
        return try unit(for: HKCategoryTypeIdentifier(rawValue: type.identifier))
    }

    static func unit(for identifier: HKQuantityTypeIdentifier) throws -> HKUnit {
        guard let unit = items[identifier]?.unit else {
            throw HKIError.noUnitFound
        }
        return unit
    }

    static func unit(for identifier: HKCategoryTypeIdentifier) throws -> HKUnit {
        guard let unit = categoryItems[identifier]?.unit else {
            throw HKIError.noUnitFound
        }
        return unit
    }

    static let items: [HKQuantityTypeIdentifier: HealthKitItem] = [
        .stepCount: HealthKitItem("stepCount", unit: HKUnit.count()),
        .flightsClimbed: HealthKitItem("flightsClimbed", unit: HKUnit.count()),

        .distanceWalkingRunning: HealthKitItem("distanceWalkingRunning", unit: HKUnit.meter()),
        .distanceCycling: HealthKitItem("distanceCycling", unit: HKUnit.meter()),
        .distanceSwimming: HealthKitItem("distanceSwimming", unit: HKUnit.meter()),

        .bodyMass: HealthKitItem("bodyMass", unit: HKUnit.gramUnit(with: .kilo)),

        .basalEnergyBurned: HealthKitItem("basalEnergyBurned", unit: HKUnit.kilocalorie()),
        .dietaryEnergyConsumed: HealthKitItem("dietaryEnergyConsumed", unit: HKUnit.kilocalorie()),

        .dietaryFatTotal: HealthKitItem("dietaryFatTotal", unit: HKUnit.gram()),
        .dietaryCarbohydrates: HealthKitItem("dietaryCarbohydrates", unit: HKUnit.gram()),
        .dietaryProtein: HealthKitItem("dietaryProtein", unit: HKUnit.gram()),
        .dietarySugar: HealthKitItem("dietarySugar", unit: HKUnit.gram()),
        .dietaryIron: HealthKitItem("dietaryIron", unit: HKUnit.gram()),
        .dietaryFiber: HealthKitItem("dietaryFiber", unit: HKUnit.gram()),
        .dietarySodium: HealthKitItem("dietarySodium", unit: HKUnit.gram()),
        .dietaryCalcium: HealthKitItem("dietaryCalcium", unit: HKUnit.gram()),

        .dietaryWater: HealthKitItem("dietaryWater", unit: HKUnit.liter()),
        .activeEnergyBurned: HealthKitItem("activeEnergyBurned", unit: HKUnit.kilocalorie())
    ]

    static let categoryItems: [HKCategoryTypeIdentifier: HealthKitItem] = [
        HKCategoryTypeIdentifier.sleepAnalysis: HealthKitItem("sleepAnalysis", unit: HKUnit.hour())
    ]
}
