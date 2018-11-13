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

    private(set) var samples: [HKSample] = []
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
    
    func add(samples: [HKSample]) {
        self.samples += samples
    }
    
    private func complete() {
        state = .ready
        Logger.log(.healthStoreService, verbose: "HKFetchAllCOntainer completed with \(samples.count) samples")
    }
}
