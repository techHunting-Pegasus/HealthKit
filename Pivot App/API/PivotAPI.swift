//
//  PivotAPI.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

enum PivotAPI {
    case refreshDevice(oldToken: String, newToken: String, userAuth: String)
    case uploadHealthData(token: String, data: [HKStatistics])
    
    static let apiVersion = "v1"
    
    func url() throws -> URL {
        var result: URL?
        guard
            let szApiUrl = Bundle.main.object(forInfoDictionaryKey: "PivotAPIURL") as? String,
            let apiUrl = URL(string: szApiUrl) else {
            throw APIError.invalidURL
        }
        
        switch self {
        case .refreshDevice:
            result = apiUrl.appendingPathComponent("\(PivotAPI.apiVersion)/users/refreshToken")
        case .uploadHealthData(let token, _):
            result = apiUrl.appendingPathComponent("\(PivotAPI.apiVersion)/gimmeData/\(token)")
        }
        
        guard let finalResult = result else {
            throw APIError.invalidURL
        }
        return finalResult
    }
    
    func httpMethod() -> String {
        switch self {
        case .refreshDevice, .uploadHealthData:
            return "PUT"
        }
    }
    
    func httpBody() throws -> Data? {
        do {
            switch self {
            case .refreshDevice(let oldToken, let newToken, _):
                return try JSONEncoder().encode(RefreshDeviceRequest(oldToken: oldToken, newToken: newToken))

            case .uploadHealthData(_, let samples):
                return try JSONEncoder().encode(HealthKitRequest(from: samples))
            }
        }
        catch {
            throw APIError.badRequestBody(error: error)
        }
    }
    func addHeaders(request: inout URLRequest) {
        switch self {
        case .refreshDevice(_, _, let userAuth):
            request.addValue("Bearer \(userAuth)", forHTTPHeaderField: "Authorization")
        case .uploadHealthData:
            break
        }
    }
    
    func request() throws -> URLRequest {
        var urlRequest = URLRequest(url: try url())
        urlRequest.httpMethod = httpMethod()
        urlRequest.httpBody = try httpBody()
        addHeaders(request: &urlRequest)
        
        return urlRequest
    }
}
