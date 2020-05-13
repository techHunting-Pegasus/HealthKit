//
//  HealthKitFetchAllContainer.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/12/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

typealias FetchAllContainerCompletion = () -> Void

protocol HealthKitFetchAllContainerDelegate: class {
    func fetchAllContainer(_: HealthKitFetchAllContainer, didComplete success: Bool)
}

class HealthKitFetchAllContainer {
    enum State: Equatable {
        case ready
        case waiting
        case uploading
    }

    private(set) var statistics: [HKStatistics] = []
    private(set) var samples: [HKSample] = []
    private(set) var anchorDates: [HKSampleType: Date] = [:]
    private(set) var activitySummaries: [HKActivitySummary] = []
    private(set) var state: State = .ready

    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        return queue
    }()

    private var completionOperations: [FetchAllContainerCompletion] = []

    private var timer: Timer?
    init() { }

    func start() {
        guard state == .ready else { return }
        state = .waiting
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] (_) in
                self?.complete()
            }
        }
    }

    func add(statistics: [HKStatistics], type: HKSampleType, anchor: Date,
             completion: FetchAllContainerCompletion? = nil) {
        guard state != .uploading else { return }
        self.statistics += statistics

        anchorDates[type] = anchor

        if let completion = completion {
            completionOperations.append(completion)
        }
    }

    func add(samples: [HKSample], type: HKSampleType, anchor: Date,
        completion: FetchAllContainerCompletion? = nil) {
        guard state != .uploading else { return }
        self.samples += samples

        anchorDates[type] = anchor

        if let completion = completion {
            completionOperations.append(completion)
        }

    }
    func add(workouts: [HKWorkout],
        completion: FetchAllContainerCompletion? = nil) {
        guard state != .uploading else { return }
        self.samples.append(contentsOf: workouts)

        if let completion = completion {
            completionOperations.append(completion)
        }

    }

    func add(activities: [HKActivitySummary],
             completion: FetchAllContainerCompletion? = nil) {
        guard state != .uploading else { return }
        self.activitySummaries = activities
    }

    private func reset() {
        statistics = []
        samples = []
        anchorDates = [:]
        completionOperations = []
        activitySummaries = []
        state = .ready
    }

    private func complete() {
        state = .ready
        Logger.log(.healthStoreService, verbose: "HKFetchAllCOntainer completed with \(statistics.count) statistics")

        guard let accessToken = UserDefaults.standard.string(forKey: Constants.accessToken) else {
            Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer No Access Token Found...")
            return
        }

        guard let refreshToken = UserDefaults.standard.string(forKey: Constants.refreshToken) else {
            Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer No Refresh Token Found...")
            return
        }

        var data: [Any] = statistics
        data.append(contentsOf: samples)

        let operation = HealthKitUploadOperation(accessToken: accessToken,
                                                 refreshToken: refreshToken,
                                                 data: data,
                                                 dailySummary: activitySummaries)

        operation.completionBlock = { [weak self, weak operation] in

            defer {
                self?.completionOperations.forEach {
                    $0()
                }

                self?.reset()
            }

            if let error = operation?.error {
                Logger.log(.healthStoreService, error: "HealthKitFetchAllContainer failed to upload data with error: \(error)")
                return
            }
            Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer Successfully Uploaded Data!")

            // Set anchors after successfull data upload.
            self?.anchorDates.forEach { (type, anchor) in
                HealthKitAnchor.set(anchor: anchor, for: type)
            }
        }

        operationQueue.addOperation(operation)
    }
}
