//
//  PivotJWT.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/19/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import Foundation


class PivotJWT {
    
    enum Errors: Error {
        case invalidJWT
        case invalidHeader
        case invalidClaims
        case claimsMissingIAT
    }
    
    let jwt: String
    
    let header: [String: Any]
    let claims: [String: Any]
        
    init(jwt: String) throws {
        self.jwt = jwt
        let components = jwt.split(separator: ".")
        
        guard components.count == 3 else {
            throw Errors.invalidJWT
        }
        
        guard let headerData = Data(base64Encoded: String(components[0]).base64Padded()),
            let headerValue =  try JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any]
        else {
            throw Errors.invalidHeader
        }
        self.header = headerValue
        
        guard let claimsData = Data(base64Encoded: String(components[1]).base64Padded()),
            let claimsValue = try JSONSerialization.jsonObject(with: claimsData, options: []) as? [String: Any]
        else {
            throw Errors.invalidClaims
        }
        
        guard claimsValue["iat"] as? Int != nil else {
            throw Errors.claimsMissingIAT
        }
        self.claims = claimsValue
    }
    
    var isExpired: Bool {
        // May need this method in the future
        return false
    }
}

extension String {
    func base64Padded() -> String {
        let toPad = count%4 == 0 ? 0 : 4 - count%4
        return self.padding(toLength: count+toPad, withPad: "=", startingAt: 0)
    }
}
