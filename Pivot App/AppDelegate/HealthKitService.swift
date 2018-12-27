//
//  HealthKitService.swift
//  Pivot
//
//  Created by Ryan Schumacher on 2/3/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit
import HealthKit

typealias AuthorizationComplete = (Bool) -> Void

class HealthKitService: NSObject, ApplicationService {
    
    static let instance = HealthKitService()
    private override init() { super.init() }
    
    static let QueryLimit = HKObjectQueryNoLimit
    static var LimitDate: Date = { // 90 days
        return Date(timeIntervalSinceNow: Date().timeIntervalSinceNow - (60 * 60 * 24 * 90))
    }()
    
    // MARK: - ApplicationService Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if HKHealthStore.isHealthDataAvailable() {            
            // Must be done on App Launch
            // https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery
            enableBackgroundDeliveries()
        }
        return true
    }
    
    
    // MARK: - Helper Methods
    func requestAuthorization(completion: AuthorizationComplete?) {
        
        store.requestAuthorization(toShare: shareSet, read: readSet) { [weak self] (success, error) in
            
            completion?(success)
            
            guard success else {
                let debugError = error.debugDescription
                Logger.log(.healthStoreService, error: "RequestAuthorization failed with Error: \(debugError)")
                return
            }
            Logger.log(.healthStoreService, info: "RequestAuthorization succeeded!")
            self?.fetchAllStatisticsData()
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
    
    private func fetchAllStatisticsData() {
        fetchAllContainer.start()
        
        for id in quantityTypeIdentifiers {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { continue }
            
            let date = Date()
            let cal = NSCalendar.current
            let newDate = cal.startOfDay(for: date)
            
            let startDate: Date?
            if let anchorDate = HealthKitAnchor.anchor(for: type) {
                startDate = anchorDate
            } else {
                startDate = cal.date(byAdding: .month, value: -3, to: newDate) ?? nil
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: newDate, options: .strictEndDate)

            var interval = DateComponents()
            interval.day = 1
            
            let options: HKStatisticsOptions
            switch type.aggregationStyle {
            case .cumulative:
                options = .cumulativeSum
            case .discrete:
                options = .discreteAverage
            }

            let statQuery = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: options, anchorDate: newDate, intervalComponents: interval)
            statQuery.initialResultsHandler = { [weak self] (query, results, error) in
                
                if let error = error {
                    Logger.log(.healthStoreService, error: "HKStatisticsCollectionQuery failed for SampleType: \(type)\nError: \(error)")
                    return
                }
                guard let statistics = results?.statistics() else {
                    Logger.log(.healthStoreService, error: "HKStatisticsCollectionQuery returned no statistics for SampleType: \(type)")
                    return
                }
                
                Logger.log(.healthStoreService, info: "HKStatisticsCollectionQuery SampleType: \(type) returned \(statistics.count) statistics")
                
                self?.fetchAllContainer.add(statistics: statistics)
            }
            
            store.execute(statQuery)
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
