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
    case uploadHealthData(token: String, data: [Any], dailySummary: [Any])
    case trackAppVisit(authToken: String)

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
        case .uploadHealthData(let token, _, _):
            if let dataPath = UserDefaults.standard.string(forKey: Constants.dataPath),
                let url = URL(string: dataPath.replacingOccurrences(of: "{accessToken}", with: token)) {
                result = url
            } else {
                result = apiUrl.appendingPathComponent("\(PivotAPI.apiVersion)/gimmeData/\(token)")
            }
        case .trackAppVisit:
            if let loginURL = UserDefaults.standard.string(forKey: Constants.loginUrl),
                let url = URL(string: loginURL)?.appendingPathComponent("/v1/auth/metrics/appVisit") {
                result = url
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
        case .trackAppVisit:
            return "POST"
        }
    }

    func httpBody() throws -> Data? {
        do {
            switch self {
            case .refreshDevice:
                return nil

            case .uploadHealthData(_, let data, let dailySummary):
                return try JSONEncoder().encode(HealthKitRequest(from: data, and: dailySummary))
                
            case .trackAppVisit:
                return nil
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
        case .trackAppVisit(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
