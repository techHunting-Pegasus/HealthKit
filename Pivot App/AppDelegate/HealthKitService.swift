//
//  HealthKitService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 2/3/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit
import HealthKit

class HealthKitService: NSObject, ApplicationService {
    
    // MARK: - ApplicationService Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()
            
            // Must be done on App Launch
            // https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery
            enableBackgroundDeliveries()
        }
        return true
    }
    
    
    // MARK: - Helper Methods
    private func requestAuthorization() {
        
        store.requestAuthorization(toShare: shareSet, read: readSet) { [weak self] (success, error) in
            guard success else {
                let debugError = error.debugDescription
                Logger.log(.healthStoreService, error: "RequestAuthorization failed with Error: \(debugError)")
                return
            }
            Logger.log(.healthStoreService, info: "RequestAuthorization succeeded!")
            self?.fetchAllData()
        }
    }
    
    private func enableBackgroundDeliveries() {

        for id in quantityTypeIdentifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }
            store.enableBackgroundDelivery(for:type, frequency: .daily) { (success, error) in
                guard success else {
                    let debugError = error.debugDescription
                    
                    Logger.log(.healthStoreService, error: "EnableBackgroundDelivery failed for \(type) with Error: \(debugError)")
                    return
                }
                Logger.log(.healthStoreService, info: "Enable Background Delivery for \(type) succeeded!")

            }
        }
    }
    
    private func fetchAllData() {
        fetchAllContainer.start()

        for id in quantityTypeIdentifiers {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { continue }
            
            let aQuery = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: HealthKitAnchor.anchor(for: type), limit: HKObjectQueryNoLimit) { [weak self] (query, samples, _, newAnchor, error) in
                
                if let error = error {
                    Logger.log(.healthStoreService, error: "HKAnchoredObjectQuery failed for SampleType: \(type)\nError: \(error)")
                    return
                }
                
                guard let samples = samples else {
                    Logger.log(.healthStoreService, warning: "HKAnchoredObjectQuery failed to get Samples for SampleType: \(type)")
                    return
                }
                
                Logger.log(.healthStoreService, info: "HKAnchoredObjectQuery SampleType: \(type) returned \(samples.count) samples")
                
                if let anchor = newAnchor {
                    HealthKitAnchor.set(anchor: anchor, for: type)
                }
                
                self?.fetchAllContainer.add(samples: samples)
                
            }
            
            store.execute(aQuery)
        }
    }
    
    // MARK: - Properties
    private let store = HKHealthStore()
    private var fetchAllContainer = HealthKitFetchAllContainer()

    private let shareSet: Set<HKSampleType>? = nil
    
    private var readSet: Set<HKObjectType>? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        var result: Set<HKObjectType> = []
        
        for id in quantityTypeIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                result.insert(type)
            }
        }
        
        for id in characteristicTypeIdentifiers {
            if let type = HKCharacteristicType.characteristicType(forIdentifier: id) {
                result.insert(type)
            }
        }
        
        return result
    }
    
    private let quantityTypeIdentifiers: [HKQuantityTypeIdentifier] = {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        var types = [
            HKQuantityTypeIdentifier.stepCount,
            HKQuantityTypeIdentifier.distanceWalkingRunning,
            HKQuantityTypeIdentifier.flightsClimbed,
            HKQuantityTypeIdentifier.bodyMass,
            HKQuantityTypeIdentifier.basalEnergyBurned,
            HKQuantityTypeIdentifier.distanceCycling]
        if #available(iOS 10, *)  {
            types.append(HKQuantityTypeIdentifier.distanceSwimming)
        }
        return types
    }()
    
    private let characteristicTypeIdentifiers: [HKCharacteristicTypeIdentifier] = {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        var types = [
            HKCharacteristicTypeIdentifier.dateOfBirth,
            HKCharacteristicTypeIdentifier.biologicalSex,
            HKCharacteristicTypeIdentifier.bloodType,
        ]
        
        return types
    }()
    
    func sampleStepCount() {
        debugPrint("Begin Sampling Step Count...")
        
    }
    
    
}
