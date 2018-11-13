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
    
    init(from samples: [HKSample]) {
        
        data = samples.compactMap { (sample) -> Sample? in
            
            switch sample {
            case let quantitySample as HKQuantitySample:
                return try? QuantitySampleRequest(from: quantitySample)
            default:
                return nil
            }
        }
    }
}

class QuantitySampleRequest: HealthKitRequest.Sample {
    enum QSRError: Error {
        case noQuantityFound
    }
    let quantity: Double
    
    init(from sample: HKQuantitySample) throws {
        self.quantity = try QuantitySampleRequest.quantity(from: sample)
        let type = try QuantitySampleRequest.type(from: sample)

        super.init(from: sample, for: type)

    }
    
    static func quantity(from sample: HKQuantitySample) throws -> Double {
        let unit: HKUnit
        switch sample.quantityType.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            unit = HKUnit.count()
            
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            unit = HKUnit.mile()
            
        case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            unit = HKUnit.count()
            
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            unit = HKUnit.pound()
            
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            unit = HKUnit.calorie()
            
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            unit = HKUnit.mile()
            
        default:
            throw QSRError.noQuantityFound
        }
        return sample.quantity.doubleValue(for: unit)
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
