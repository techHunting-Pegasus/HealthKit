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
    case uploadHealthData(token: String, data: [Any])

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
            if let dataPath = UserDefaults.standard.string(forKey: Constants.dataPath),
                let url = URL(string: dataPath.replacingOccurrences(of: "{accessToken}", with: token)) {
                result = url
            } else {
                result = apiUrl.appendingPathComponent("\(PivotAPI.apiVersion)/gimmedata/\(token)")
            }
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

            case .uploadHealthData(_, let data):
                return try JSONEncoder().encode(HealthKitRequest(from: data))
            }
        } catch {
            throw APIError.badRequestBody(error: error)
        }
    }
    func addHeaders(request: inout URLRequest) {
        switch self {
        case .refreshDevice:
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected response is also JSON
        case .uploadHealthData:
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected response is also JSON
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
