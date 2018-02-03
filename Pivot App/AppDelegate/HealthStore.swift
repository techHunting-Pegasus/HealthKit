//
//  HealthStore.swift
//  Pivot
//
//  Created by Ryan Schumacher on 2/3/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class HealthStore {
    enum HealthStoreError: Error {
        case healthKitUnavailable
        case healtKitError(Error)
    }
    
    static let shared = HealthStore()

    let store = HKHealthStore()
    
    private init() { }
    
    func requestAuthorization(completion: @escaping (Bool, Error?)->()) {
        guard HKHealthStore.isHealthDataAvailable() else {
            return completion(false, HealthStoreError.healthKitUnavailable)
        }
        store.requestAuthorization(toShare: shareSet, read: readSet, completion: completion)
    }
    
    let shareSet: Set<HKSampleType>? = nil
    
    let readSet: Set<HKObjectType>? = {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        var result: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)!
        ]
        
        if #available(iOS 10, *)  {
            result.insert(HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceSwimming)!)
        }
        
        return result
    }()
}
