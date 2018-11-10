//
//  HealthStore.swift
//  Pivot
//
//  Created by Ryan Schumacher on 2/3/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit
import HealthKit

class HealthStoreService: NSObject, ApplicationService {
    
    // MARK: - ApplicationService Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()
            enableBackgroundDeliveries()
            beginObservations()
        }
        return true
    }
    
    
    // MARK: - Helper Methods
    private func requestAuthorization() {
        
        store.requestAuthorization(toShare: shareSet, read: readSet) { (success, error) in
            if let error = error {
                print("HealthStoreService RequestAuthorization Error: \(error)")
                return
            }
            print("HealthStoreService Successfully Requested Authorization.")
        }
    }
    
    private func enableBackgroundDeliveries() {

        let stepCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        store.enableBackgroundDelivery(for:stepCount, frequency: .hourly) { (success, error) in
            guard error == nil else {
                print("HealthStoreService enableBackgroundDeliveries Error: \(error!)")
                return
            }
            print("HealthStoreService Successfully Enabled Background Delivereies.")
        }
    }
    
    private func beginObservations() {

        for id in typeIdentifiers {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { continue }
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self]
                (query, completionHandler, error) in
                guard error == nil else {
                    print("HealthStoreService Error Creating Observer Query for SampleType: \(type)\nError: \(error!)")
                    completionHandler()
                    return
                }
                print("HealthStoreService Received Observation for SampleType\(type)")
                
                switch type.identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    self?.sampleStepCount()
                default:
                    debugPrint("Unhandled Sample Type")
                    break
                }
                
                

                completionHandler()
            }
            
            store.execute(query)
        }
    }
    
    // MARK: - Properties
    private let store = HKHealthStore()

    private let shareSet: Set<HKSampleType>? = nil
    
    private var readSet: Set<HKObjectType>? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        var result: Set<HKObjectType> = []
        
        for id in typeIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                result.insert(type)
            }
        }
        
        return result
    }
    
    private let typeIdentifiers: [HKQuantityTypeIdentifier] = {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        var types = [
            HKQuantityTypeIdentifier.stepCount,
            HKQuantityTypeIdentifier.distanceWalkingRunning,
            HKQuantityTypeIdentifier.distanceCycling]
        if #available(iOS 10, *)  {
            types.append(HKQuantityTypeIdentifier.distanceSwimming)
        }
        return types
    }()
    
    func sampleStepCount() {
        debugPrint("Begin Sampling Step Count...")
        
    }
    
    
}
