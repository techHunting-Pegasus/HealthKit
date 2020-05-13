//
//  HealthKitUploadOperation.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 1/9/19.
//  Copyright © 2019 Schu Studios, LLC. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitUploadOperation: Operation {

    enum UploadError: Error {
        case createUploadRequestFailed
        case invalidUploadResponse(Error?)
        case unknownUploadResponseCode(Int, Error?)

        case createRefreshRequestFailed
        case emptyRefreshTokenResponse
        case invalidRefreshResponse(Error?)
        case unknownRefreshResponseCode(Int, Error?)
    }

    private(set) var accessToken: String
    private(set) var refreshToken: String
    let data: [Any]
    let dailySummary: [Any]
    var error: Error?

    private var hasRefreshedToken: Bool = false

    init(accessToken: String, refreshToken: String, data: [Any], dailySummary: [Any]) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.data = data
        self.dailySummary = dailySummary
        super.init()
    }

    override var isAsynchronous: Bool { return true }
    private var _isFinished: Bool = false
    override var isFinished: Bool {
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
        get { return _isFinished }
    }

    private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
        get { return _isExecuting }

    }

    private func finish(with error: Error? = nil) {
        self.error = error
        isExecuting = false
        isFinished = true

        if let error = error {
            Analytics.track(event: .healthKitDataUploadFailed(error, data.count))
        } else {
            Analytics.track(event: .healthKitDataUploadSucceeded(data.count))
        }
    }

    override func start() {

        isExecuting = true

        startUploadRequest()
    }
    private func startUploadRequest() {
        guard let uploadRequest = try? PivotAPI.uploadHealthData(token: accessToken, data: data, dailySummary: dailySummary).request() else {
            finish(with: UploadError.createUploadRequestFailed)
            return
        }

        let task = URLSession.shared.dataTask(with: uploadRequest) {[weak self] (data, response, error) in

            guard self?.isCancelled == false else { return }

            guard let httpResponse = response as? HTTPURLResponse else {
                self?.finish(with: UploadError.invalidUploadResponse(error))
                return
            }

            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200:
                self?.finish()
            case 401 where self?.hasRefreshedToken == false:
                self?.callRefreshToken()
            default:
                self?.finish(with: UploadError.unknownUploadResponseCode(statusCode, error))
            }

        }

        task.resume()
    }

    private func callRefreshToken() {

        guard let request = try? PivotAPI.refreshDevice(oldToken: accessToken, refreshToken: refreshToken).request() else {
            finish(with: UploadError.createRefreshRequestFailed)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard self?.isCancelled == false else { return }

            guard let data = data else {
                self?.finish(with: UploadError.emptyRefreshTokenResponse)
                return
            }

            guard let tokenResponse = try? JSONDecoder().decode(HealthKitRefreshTokenResponse.self, from: data) else {
                self?.finish(with: UploadError.invalidRefreshResponse(nil))
                return
            }


            // Update tokens
            UserDefaults.standard.set(tokenResponse.accessToken, forKey: Constants.accessToken)
            self?.accessToken = tokenResponse.accessToken

            UserDefaults.standard.set(tokenResponse.refreshToken, forKey: Constants.refreshToken)
            self?.refreshToken = tokenResponse.refreshToken
            self?.hasRefreshedToken = true

            UserDefaults.standard.set(tokenResponse.dataPath, forKey: Constants.dataPath)

            self?.startUploadRequest()

        }
        task.resume()
    }
}
