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
    private(set) var anchorDates: [HKSampleType: Date] = [:]
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
        
        DispatchQueue.global(qos: .background).async { [weak self] in

            guard let accessToken = UserDefaults.standard.string(forKey: Constants.access_token) else {
                Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer No Access Token Found...")
                return
            }

            if let strongSelf = self,
                let request = try? PivotAPI.uploadHealthData(token: accessToken, data: strongSelf.statistics).request() {
                let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                    if let error = error {
                        Logger.log(.healthStoreService, error: "HealthKitFetchAllContainer failed to upload data with error: \(error)")
                        self?.reset()
                        return
                    }
                    Logger.log(.healthStoreService, info: "HealthKitFetchAllContainer Successfully Uploaded Data!")
                    
                    if let url = request.url, let httpResponse = response as? HTTPURLResponse {
                        Logger.log(.healthStoreService, verbose: "Uploaded data to: \(url)")
                        Logger.log(.healthStoreService, verbose: "With Response code: \(httpResponse.statusCode)")
                    }
                    
                    // Set anchors after successfull data upload.
                    self?.anchorDates.forEach { (type, anchor) in
                        HealthKitAnchor.set(anchor: anchor, for: type)
                    }
                    
                    self?.reset()
                }
                
                dataTask.resume()
                #if DEBUG
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let url = documentsURL.appendingPathComponent("hkdata_\(NSDate().timeIntervalSince1970).json")
                    try? request.httpBody?.write(to: url)
                }
                #endif
            }
        }
    }
}
