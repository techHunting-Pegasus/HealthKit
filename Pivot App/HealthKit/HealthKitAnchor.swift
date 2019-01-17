//
//  HealthKitAnchor.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/10/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

enum HealthKitAnchor {

    static func anchor(for sampleType: HKSampleType) -> Date? {
//        let udName = name(for: sampleType)
//
//        guard let date = UserDefaults.standard.object(forKey: udName) as? Date else {
//            UserDefaults.standard.set(nil, forKey: udName)
//            return nil
//        }
//
//        #if NO_ANCHOR
//        return nil
//        #else
//        return date
//        #endif
        return nil
    }

    static func set(anchor: Date, for sampleType: HKSampleType) {
        let udName = name(for: sampleType)

        UserDefaults.standard.setValue(anchor, forKeyPath: udName)
    }

    private static func name(for sampleType: HKSampleType) -> String {

        return "anchor_\(sampleType.identifier)"

    }
}
