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

    static func anchor(for sampleType: HKSampleType) -> HKQueryAnchor {
        guard let udName = name(for: sampleType),
            let data = UserDefaults.standard.object(forKey: udName) as? Data,
            let anchor = NSKeyedUnarchiver.unarchiveObject(with: data) as? HKQueryAnchor else {
                return HKQueryAnchor(fromValue: HKObjectQueryNoLimit)
        }
        
        return anchor
    }
    
    static func set(anchor: HKQueryAnchor, for sampleType: HKSampleType) {
        guard let udName = name(for: sampleType) else { return }
        
        let archive = NSKeyedArchiver.archivedData(withRootObject: anchor)
        
        UserDefaults.standard.setValue(archive, forKeyPath: udName)
    }
    
    private static func name(for sampleType: HKSampleType) -> String? {
        
        return "achor_\(sampleType.identifier)"
        
    }
}
