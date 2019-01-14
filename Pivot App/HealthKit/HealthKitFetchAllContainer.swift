//
//  HealthKitFetchAllContainer.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/12/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

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
    private(set) var anchorDates: [HKSampleType: Date] = [:]
    private(set) var state: State = .ready

    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        return queue
    }()

    private var timer: Timer?
    init() { }

    func start() {
        guard state == .ready else { return }
        state = .waiting
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] (_) in
                self?.complete()
            }
        }
    }

    func add(statistics: [HKStatistics], type: HKSampleType, anchor: Date) {
        guard state != .uploading else { return }
        self.statistics += statistics

        anchorDates[type] = anchor
    }

    private func reset() {
        statistics = []
        anchorDates = [:]
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

        let operation = HealthKitUploadOperation(accessToken: accessToken, refreshToken: refreshToken, data: statistics)

        operation.completionBlock = { [weak self, weak operation] in

            if let error = operation?.error {
                Logger.log(.healthStoreService, error: "HealthKitFetchAllContainer failed to upload data with error: \(error)")
                self?.reset()
                return
            }
            Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer Successfully Uploaded Data!")

            // Set anchors after successfull data upload.
            self?.anchorDates.forEach { (type, anchor) in
                HealthKitAnchor.set(anchor: anchor, for: type)
            }

            self?.reset()
        }

        operationQueue.addOperation(operation)
    }
}
