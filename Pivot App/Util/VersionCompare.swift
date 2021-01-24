//
//  VersionCompare.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/24/21.
//  Copyright © 2021 Schu Studios, LLC. All rights reserved.
//

import Foundation


extension String {
    func versionCompare(_ other: String) -> ComparisonResult {

        let versionDelimit = "."

        var leftVersionComps = self.components(separatedBy: versionDelimit)
        var rightVersionComps = other.components(separatedBy: versionDelimit)

        let zeroDiff = leftVersionComps.count - rightVersionComps.count

        guard zeroDiff != 0 else {
            return self.compare(other, options: .numeric)
        }

        let zeros = Array(repeating: "0", count: abs(zeroDiff))

        if zeroDiff > 0 {
            rightVersionComps.append(contentsOf: zeros)
        } else {
            leftVersionComps.append(contentsOf: zeros)
        }

        return leftVersionComps.joined(separator: versionDelimit)
            .compare(rightVersionComps.joined(separator: versionDelimit), options: .numeric)
    }
}
