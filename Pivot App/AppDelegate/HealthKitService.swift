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
typealias InitialResultsHandlerType = ((HKStatisticsCollectionQuery, HKStatisticsCollection?, Error?, Date) -> Void)?

class HealthKitService: NSObject, ApplicationService {

    static let instance = HealthKitService()
    private override init() { super.init() }

    static let QueryLimit = HKObjectQueryNoLimit
    static var LimitDate: Date = { // 90 days
        return Date(timeIntervalSinceNow: Date().timeIntervalSinceNow - (60 * 60 * 24 * 90))
    }()

    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        return queue
    }()

    // MARK: - ApplicationService Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if HKHealthStore.isHealthDataAvailable() {
            // Must be done on App Launch
            // https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery
            enableBackgroundDeliveries()
            // start observer queries
            startObserverQueries()
        }
        return true
    }


    // MARK: - Helper Methods
    func requestAuthorization(completion: AuthorizationComplete?) {

        store.requestAuthorization(toShare: shareSet, read: readSet) { (success, error) in

            completion?(success)

            guard success else {
                let debugError = error.debugDescription
                Logger.log(.healthStoreService, error: "RequestAuthorization failed with Error: \(debugError)")
                return
            }
            Logger.log(.healthStoreService, info: "RequestAuthorization succeeded!")
        }
    }

    func storeTokens(_ tokens: HealthKitTokens) {
        UserDefaults.standard.set(tokens.accessToken, forKey: Constants.accessToken)
        UserDefaults.standard.set(tokens.refreshToken, forKey: Constants.refreshToken)
        UserDefaults.standard.set(tokens.dataMationID, forKey: Constants.datamationId)
    }

    private func startObserverQueries() {
        for id in quantityTypeIdentifiers {

            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }

            let query = HKObserverQuery(sampleType: type, predicate: nil) {[weak self] (query, completionHandler, _error) in
                if let error = _error {
                    Logger.log(.healthStoreService, error: "Observer Query failed for Quantity Type: \(type) with error:\(error)")
                    completionHandler()
                    return
                }

                Logger.log(.healthStoreService, info: "Observer Query Succeeded for Quantity Type: \(type)")

                self?.fetchStatisticsData(for: type) { (query, results, error, newDate) in
                    var didSucceed = false
                    defer {
                        if didSucceed == false {
                            completionHandler()
                        }
                    }
                    if let error = error {
                        Logger.log(.healthStoreService, error: "ObserverQuery HKStatisticsCollectionQuery failed for SampleType: \(type)\nError: \(error)")
                        return
                    }
                    guard let statistics = results?.statistics() else {
                        Logger.log(.healthStoreService, error: "ObserverQuery HKStatisticsCollectionQuery failed to get statistics for SampleType: \(type)")
                        return
                    }
                    guard statistics.count > 0 else {
                        Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery returned empty statistics for SampleType: \(type)")
                        return
                    }

                    guard let accessToken = UserDefaults.standard.string(forKey: Constants.accessToken) else {
                        Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery No Access Token Found...")
                        return
                    }

                    guard let refreshToken = UserDefaults.standard.string(forKey: Constants.refreshToken) else {
                        Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery No Refresh Token Found...")
                        return
                    }

                    Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery SampleType: \(type) returned \(statistics.count) statistics")

                    didSucceed = true

                    let operation = HealthKitUploadOperation(accessToken: accessToken, refreshToken: refreshToken, data: statistics)

                    operation.completionBlock = { [weak operation] in

                        defer {
                            completionHandler()
                        }

                        if let error = operation?.error {
                            Logger.log(.healthStoreService, error: "ObserverQuery HKStatisticsCollectionQuery failed to upload data with error: \(error)")
                            return
                        }
                        Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery Successfully Uploaded Data!")

                        // Update the anchor on success
                        HealthKitAnchor.set(anchor: newDate, for: type)
                    }

                    self?.operationQueue.addOperation(operation)
                }

            }
            store.execute(query)
        }
    }

    private func enableBackgroundDeliveries() {

        for id in quantityTypeIdentifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }
            store.enableBackgroundDelivery(for:type, frequency: .hourly) { (success, error) in
                guard success else {
                    let debugError = error.debugDescription

                    Logger.log(.healthStoreService, error: "EnableBackgroundDelivery failed for \(type) with Error: \(debugError)")
                    return
                }
                Logger.log(.healthStoreService, info: "Enable Background Delivery for \(type) succeeded!")

            }
        }
    }

    func fetchAllStatisticsData() {
        fetchAllContainer.start()

        for id in quantityTypeIdentifiers {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { continue }

            fetchStatisticsData(for: type) { [weak self] (query, results, error, newDate) in

                if let error = error {
                    Logger.log(.healthStoreService, error: "HKStatisticsCollectionQuery failed for SampleType: \(type)\nError: \(error)")
                    return
                }
                guard let statistics = results?.statistics() else {
                    Logger.log(.healthStoreService, error: "HKStatisticsCollectionQuery returned no statistics for SampleType: \(type)")
                    return
                }

                Logger.log(.healthStoreService, info: "HKStatisticsCollectionQuery SampleType: \(type) returned \(statistics.count) statistics")

                self?.fetchAllContainer.add(statistics: statistics, type: type, anchor: newDate)
            }
        }
    }

    private func fetchStatisticsData(for type: HKQuantityType, completion: InitialResultsHandlerType) {

        let date = Date()
        let cal = NSCalendar.current
        let newDate = cal.startOfDay(for: date)

        let startDate: Date?
        if let anchorDate = HealthKitAnchor.anchor(for: type) {
            startDate = anchorDate
        } else {
            startDate = cal.date(byAdding: .month, value: -3, to: newDate) ?? nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: date, options: .strictEndDate)

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

        statQuery.initialResultsHandler = { (query, results, error) in
            completion?(query, results, error, newDate)
        }

        store.execute(statQuery)

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

    private var  quantityTypeIdentifiers: [HKQuantityTypeIdentifier] {
        return HealthKitItems.quantityTypeIdentifiers
    }

    private let characteristicTypeIdentifiers: [HKCharacteristicTypeIdentifier] = {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        var types = [
            HKCharacteristicTypeIdentifier.dateOfBirth,
            HKCharacteristicTypeIdentifier.bloodType,
            ]

        return types
    }()

    func sampleStepCount() {
        debugPrint("Begin Sampling Step Count...")

    }


}
