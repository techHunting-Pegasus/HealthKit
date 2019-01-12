//
//  HealthKitPostDataOperation.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/11/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitPostDataOperation: Operation {

    let token: String
    let data: [HKStatistics]

    init(token: String, data: [HKStatistics]) {
        self.token = token
        self.data = data
        super.init()
    }

    override var isAsynchronous: Bool { return true }
    private var _isFinished: Bool = false
    override var isFinished: Bool {
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
        get { return _isFinished }
    }

    private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
        get { return _isExecuting }

    }

    

    override func start() {




    }
}
