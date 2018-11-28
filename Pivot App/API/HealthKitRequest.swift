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
    var data: [Sample] = []
    
    class Sample: Encodable {
        let startDate: Date
        let endDate: Date
        let type: String
        
        fileprivate init(from sample: HKSample, for type: String) {
            self.startDate = sample.startDate
            self.endDate = sample.endDate
            self.type = type
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    init(from samples: [HKSample]) {
        var index = 0
        var lastPercent: Int = 0
        data = samples.compactMap { (sample) -> Sample? in
            let currentPercent: Int = (index / samples.count) * 10
            if lastPercent < currentPercent {
                Logger.log(.healthStoreService, verbose: "Processing Data: \(currentPercent)0%...")
                lastPercent = currentPercent
                index += 1
            }
            
            switch sample {
            case let quantitySample as HKQuantitySample:
                return try? QuantitySampleRequest(from: quantitySample)
            default:
                return nil
            }
        }
        Logger.log(.healthStoreService, info: "Finished Processing Data!")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var dataContainer = container.nestedUnkeyedContainer(forKey: .data)
        try data.forEach { (sample) in
            if let quantitySample = sample as? QuantitySampleRequest {
                try dataContainer.encode(quantitySample)
            } else {
                try dataContainer.encode(sample)
            }
        }
        
    }
}

class QuantitySampleRequest: HealthKitRequest.Sample {
    enum QSRError: Error {
        case noQuantityFound
        case noUnitFound
    }
    let quantity: Double
    let unit: String
    
    init(from sample: HKQuantitySample) throws {
        let unit = try QuantitySampleRequest.unit(from: sample)
        self.quantity = sample.quantity.doubleValue(for: unit)
        self.unit = unit.unitString

        let type = try QuantitySampleRequest.type(from: sample)

        super.init(from: sample, for: type)

    }
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case startDate
        case endDate
        case type
        case unit
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
    
//    static func quantity(from sample: HKQuantitySample) throws -> String {
//        switch sample.quantityType.identifier {
//        case HKQuantityTypeIdentifier.stepCount.rawValue:
//            return "count"
//
//        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
//            return "m"
//
//        case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
//            return "count"
//
//        case HKQuantityTypeIdentifier.bodyMass.rawValue:
//            unit = "kg"
//
//        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
//            unit = "kilocalorie"
//
//        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
//            unit =  "m"
//
//        default:
//            throw QSRError.noUnitFound
//        }
//        return sample.quantity.doubleValue(for: unit)
//    }
    static func unit(from sample: HKQuantitySample) throws -> HKUnit {
        let unit: HKUnit
        switch sample.quantityType.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            unit = HKUnit.count()
            
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            unit = HKUnit.meter()
            
        case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            unit = HKUnit.count()
            
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            unit = HKUnit.gramUnit(with: .kilo)
            
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            unit = HKUnit.kilocalorie()
            
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            unit = HKUnit.meter()
            
        default:
            throw QSRError.noUnitFound
        }
        return unit
    }

    static func type(from sample: HKQuantitySample) throws -> String {
        switch sample.quantityType.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "stepCount"
            
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return "distanceWalkingRunning"
            
        case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            return "flightsClimbed"
            
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return "bodyMass"
            
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            return "basalEnergyBurned"
            
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            return "distanceCycling"
            
        default:
            throw QSRError.noQuantityFound
        }
    }
}
