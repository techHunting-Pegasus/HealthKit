//
//  PivotAPI.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation

enum PivotAPI {
    case refreshDevice(oldToken: String, newToken: String, userAuth: String)
    
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
            result = URL(string: "/\(PivotAPI.apiVersion)/users/refreshToken", relativeTo: apiUrl)
        }
        
        guard let finalResult = result else {
            throw APIError.invalidURL
        }
        return finalResult
    }
    
    func httpMethod() -> String {
        switch self {
        case .refreshDevice:
            return "POST"
        }
    }
    
    func httpBody() throws -> Data? {
        do {
            switch self {
            case .refreshDevice(let oldToken, let newToken, _):
                return try JSONEncoder().encode(RefreshDeviceRequest(oldToken: oldToken, newToken: newToken))
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
