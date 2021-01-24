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
typealias CategoryResultsHandlerType = (HKSampleQuery, [HKSample]?, Error?) -> Void
typealias WorkoutResultsHandlerType = (HKSampleQuery, [HKWorkout], Date) -> Void
typealias ActivityResultsHandlerType = (HKActivitySummaryQuery, [HKActivitySummary]?, Error?) -> Void

class HealthKitService: NSObject, ApplicationService {

    enum StartDate {
        case oneMonth
        case threeMonths
    }

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
            Analytics.track(event: .healthKitEnabled)

            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                UserDefaults.standard.setValue(appVersion, forKey:Constants.lastHKAuthVersion)
            }
        }
    }

    func storeTokens(_ tokens: HealthKitTokens) {
        UserDefaults.standard.set(tokens.accessToken, forKey: Constants.accessToken)
        UserDefaults.standard.set(tokens.refreshToken, forKey: Constants.refreshToken)
        UserDefaults.standard.set(tokens.dataMationID, forKey: Constants.datamationId)
    }

    private func startObserverQueries() {

        fetchAllContainer.start()

        for id in quantityTypeIdentifiers {

            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }

            let query = HKObserverQuery(sampleType: type, predicate: nil) {[weak self] (query, completionHandler, _error) in
                if let error = _error {
                    Logger.log(.healthStoreService, error: "Observer Query failed for Quantity Type: \(type) with error:\(error)")
                    completionHandler()
                    return
                }

                Logger.log(.healthStoreService, info: "Observer Query Succeeded for Quantity Type: \(type)")

                self?.fetchStatisticsData(for: type, start: .oneMonth) { (query, results, error, newDate) in
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

                    Logger.log(.healthStoreService, info: "ObserverQuery HKStatisticsCollectionQuery SampleType: \(type) returned \(statistics.count) statistics")

                    didSucceed = true

                    self?.fetchAllContainer.add(statistics: statistics, type: type, anchor: newDate) {
                        completionHandler()
                    }

                }

            }

            store.execute(query)
        }

        let workoutQuery = HKObserverQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil) {
            [weak self] (query, completionHandler, error) in

            self?.fetchWorkoutData(start: .oneMonth) { [weak self] (query, workouts, newDate) in

                self?.fetchAllContainer.add(workouts: workouts) {
                    completionHandler()
                }

            }
        }

        store.execute(workoutQuery)


        self.fetchActivityData(start: .oneMonth) {
            [weak self] (query, activities, error) in
            if let error = error {
                print("Failed to query activity with error: \(error)")
            }

            self?.fetchAllContainer.add(activities: activities ?? [])
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

            fetchStatisticsData(for: type, start: .threeMonths) { [weak self] (query, results, error, newDate) in

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

        for id in categoryTypeIdentifiers {
            guard let type = HKObjectType.categoryType(forIdentifier: id) else { continue }

            fetchCategoryData(for: type, start: .threeMonths) { [weak self] (query, samples: [HKSample]?, error) in
                if let error = error {
                    Logger.log(.healthStoreService, error: "HKCategorySample failed for SampleType: \(type)\nError: \(error)")
                    return
                }

                guard let results = samples else {
                    Logger.log(.healthStoreService, error: "HKCategorySample returned no data for SampleType: \(type)")
                    return
                }

                Logger.log(.healthStoreService, info: "HKStatisticsCollectionQuery SampleType: \(type) returned \(results.count) Samples")

                // TODO: Use date returned from fetch method
                self?.fetchAllContainer.add(samples: results, type: type, anchor: Date())
            }
        }

        fetchWorkoutData(start: .threeMonths) { [weak self] (query, workouts, newDate) in

            self?.fetchAllContainer.add(workouts: workouts)
        }

        fetchActivityData(start: .oneMonth) {
            [weak self] (query, activities, error) in
            if let error = error {
                print("Failed to query activity with error: \(error)")
            }
            self?.fetchAllContainer.add(activities: activities ?? [])
        }

    }

    private func fetchStatisticsData(for type: HKQuantityType, start: StartDate,
                                     completion: InitialResultsHandlerType) {

        let date = Date()
        let cal = NSCalendar.current
        let newDate = cal.startOfDay(for: date)

        let startDate: Date?

        switch start {
        case .oneMonth:
            startDate = cal.date(byAdding: .month, value: -1, to: newDate)
        case .threeMonths:
            startDate = cal.date(byAdding: .month, value: -3, to: newDate)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil,
                                                    options: .strictEndDate)

        var interval = DateComponents()
        interval.day = 1

        let options: HKStatisticsOptions
        switch type.aggregationStyle {
        case .cumulative:
            options = .cumulativeSum
        case .discrete:
            options = .discreteAverage
        case .discreteTemporallyWeighted:
            options = .discreteAverage
        case .discreteEquivalentContinuousLevel:
            options = .discreteAverage
        case .discreteArithmetic:
            options = .discreteAverage
        @unknown default:
            assertionFailure("Cannot find additional aggregation style")
            options = .cumulativeSum
        }

        let statQuery = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: options, anchorDate: newDate, intervalComponents: interval)

        statQuery.initialResultsHandler = { (query, results, error) in
            completion?(query, results, error, newDate)
        }

        store.execute(statQuery)
    }

    private func fetchActivityData(start: StartDate, complete: @escaping ActivityResultsHandlerType) {
        let calendar = NSCalendar.current
        let endDate = Date()

        guard let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) else {
            fatalError("*** Unable to create the start date ***")
        }

        let units: Set<Calendar.Component> = [.day, .month, .year, .era]


        var startDateComponents = calendar.dateComponents(units, from: startDate)
        startDateComponents.calendar = calendar


        var endDateComponents = calendar.dateComponents(units, from: endDate)
        endDateComponents.calendar = calendar

        let summariesWithinRange = HKQuery.predicate(forActivitySummariesBetweenStart: startDateComponents,
                                                     end: endDateComponents)

        let activitySummaryQuery = HKActivitySummaryQuery(predicate: summariesWithinRange, resultsHandler: complete)

        store.execute(activitySummaryQuery)
    }


    private func fetchWorkoutData(start: StartDate, complete: @escaping WorkoutResultsHandlerType) {
        let date = Date()
        let cal = NSCalendar.current
        let newDate = cal.startOfDay(for: date)

        let startDate: Date?

        switch start {
        case .oneMonth:
            startDate = cal.date(byAdding: .month, value: -1, to: newDate)
        case .threeMonths:
            startDate = cal.date(byAdding: .month, value: -3, to: newDate)
        }

//        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
//            fatalError("*** Unable to create the distance type ***")
//        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil,
                                                    options: .strictEndDate)


        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: nil) { (query, _samples, _error) in

            if let error = _error {
                Logger.log(.healthStoreService, error: "HKSampleQuery for Workouts failed with Error: \(error)")
                return
            }

            guard let samples = _samples else {
                Logger.log(.healthStoreService, error: "HKSampleQuery for Workouts found no samples")
                return
            }

            let workouts = samples.compactMap { (sample) -> HKWorkout? in
                return sample as? HKWorkout
            }

            complete(query, workouts, Date())
        }

        store.execute(query)

    }

    private func fetchCategoryData(for type: HKCategoryType, start: StartDate,
                                   completion: @escaping CategoryResultsHandlerType) {
        let date = Date()
        let cal = NSCalendar.current
        let newDate = cal.startOfDay(for: date)

        let startDate: Date?

        switch start {
        case .oneMonth:
            startDate = cal.date(byAdding: .month, value: -1, to: newDate)
        case .threeMonths:
            startDate = cal.date(byAdding: .month, value: -3, to: newDate)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil,
                                                    options: .strictEndDate)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil, resultsHandler: completion)

        store.execute(query)
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

        for id in categoryTypeIdentifiers {
            if let type = HKObjectType.categoryType(forIdentifier: id) {
                result.insert(type)
            }
        }

        for id in characteristicTypeIdentifiers {
            if let type = HKCharacteristicType.characteristicType(forIdentifier: id) {
                result.insert(type)
            }
        }

        result.insert(HKWorkoutType.workoutType())
        result.insert(HKObjectType.activitySummaryType())

        return result
    }

    private var  quantityTypeIdentifiers: [HKQuantityTypeIdentifier] {
        return HealthKitItems.quantityTypeIdentifiers
    }

    private var categoryTypeIdentifiers: [HKCategoryTypeIdentifier] {
        return HealthKitItems.categoryTypeIdentifiers
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
