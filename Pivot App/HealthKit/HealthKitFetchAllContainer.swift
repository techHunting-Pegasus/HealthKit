//
//  HealthKitFetchAllContainer.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/12/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

protocol HealthKitFetchAllContainerDelegate {
    func fetchAllContainer(_: HealthKitFetchAllContainer, didComplete success: Bool)
}

class HealthKitFetchAllContainer {
    enum State: Equatable {
        case ready
        case waiting
        case uploading
    }

    private(set) var statistics: [HKStatistics] = []
    private(set) var anchors: [HKSampleType: HKQueryAnchor] = [:]
    private(set) var state: State = .ready
    
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
    
    func add(statistics: [HKStatistics]) {
        guard state != .uploading else { return }
        self.statistics += statistics
    }

    private func reset() {
        statistics = []
        anchors = [:]
        state = .ready
    }
    
    private func complete() {
        state = .ready
        Logger.log(.healthStoreService, verbose: "HKFetchAllCOntainer completed with \(statistics.count) statistics")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            if let strongSelf = self,
                let request = try? PivotAPI.uploadHealthData(strongSelf.statistics).request() {
                let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                    if let error = error {
                        Logger.log(.healthStoreService, error: "HealthKitFetchAllContainer failed to upload data with error: \(error)")
                        self?.reset()
                        return
                    }
                    // Set anchors after successfull data upload.
                    self?.anchors.forEach { (type, anchor) in
                        HealthKitAnchor.set(anchor: anchor, for: type)
                    }
                    
                    self?.reset()
                }
                
                dataTask.resume()
            }
        }

    }
}
