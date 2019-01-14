//
//  PivotAPI.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

enum PivotAPI {
    case refreshDevice(oldToken: String, refreshToken: String)
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
        case .refreshDevice(let accessToken, let refreshToken):
            result = apiUrl.appendingPathComponent("\(PivotAPI.apiVersion)/reAuth/\(accessToken)/\(refreshToken)")
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
        case .refreshDevice:
            return "GET"
        case .uploadHealthData:
            return "PUT"
        }
    }

    func httpBody() throws -> Data? {
        do {
            switch self {
            case .refreshDevice:
                return nil

            case .uploadHealthData(_, let samples):
                return try JSONEncoder().encode(HealthKitRequest(from: samples))
            }
        } catch {
            throw APIError.badRequestBody(error: error)
        }
    }
    func addHeaders(request: inout URLRequest) {
        switch self {
        case .refreshDevice:
            break
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
