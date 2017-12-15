//
//  PivotAPI.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation

enum PivotAPI {
    case registerDevice(token: String, guid: String)
    
    static let apiVersion = "v1"
    
    func url() throws -> URL {
        var result: URL?
        guard
            let szApiUrl = Bundle.main.object(forInfoDictionaryKey: "PivotAPIURL") as? String,
            let apiUrl = URL(string: szApiUrl) else {
            throw APIError.invalidURL
        }
        
        switch self {
        case .registerDevice:
            result = URL(string: "/\(PivotAPI.apiVersion)/registerDevice", relativeTo: apiUrl)
        }
        
        guard let finalResult = result else {
            throw APIError.invalidURL
        }
        return finalResult
    }
    
    func httpMethod() -> String {
        switch self {
        case .registerDevice:
            return "POST"
        }
    }
    
    func httpBody() throws -> Data? {
        do {
            switch self {
            case .registerDevice(let token, let guid):
                return try JSONEncoder().encode(RegisterDeviceRequest(token: token, uniqueIdentifier: guid))
            }
        }
        catch {
            throw APIError.badRequestBody(error: error)
        }
    }
    
    func request() throws -> URLRequest {
        var urlRequest = URLRequest(url: try url())
        urlRequest.httpMethod = httpMethod()
        urlRequest.httpBody = try httpBody()
        
        return urlRequest
    }
}
