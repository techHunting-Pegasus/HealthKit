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
        case createRefreshRequestFailed
        case invalidResponse(Error?)
        case unknownResponseCode(Int, Error?)
    }

    private(set) var userToken: String
    let refreshToken: String
    let data: [HKStatistics]

    var error: Error?

    init(userToken: String, refreshToken: String, data: [HKStatistics]) {
        self.userToken = userToken
        self.refreshToken = refreshToken
        self.data = data
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
    }

    override func start() {

        isExecuting = true

        guard let uploadRequest = try? PivotAPI.uploadHealthData(token: userToken,
                                                                 data: data).request() else {
            finish(with: UploadError.createUploadRequestFailed)
            return
        }

        let task = URLSession.shared.dataTask(with: uploadRequest) {[weak self] (data, response, error) in

            guard self?.isCancelled == false else { return }

            guard let httpResponse = response as? HTTPURLResponse else {
                self?.finish(with: UploadError.invalidResponse(error))
                return
            }

            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200:
                self?.finish()
            case 401:
                self?.callRefreshToken()
            default:
                self?.finish(with: UploadError.unknownResponseCode(statusCode, error))
            }

        }

        task.resume()
    }

    private func callRefreshToken() {

        guard let request = try? PivotAPI.refreshDevice(oldToken: userToken, refreshToken: refreshToken).request() else {
            finish(with: UploadError.createRefreshRequestFailed)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard self?.isCancelled == false else { return }

//            guard let httpResponse = response as? HTTPURLResponse else {
//                self?.finish(with: UploadError.invalidResponse(error))
//                return
//            }

            if let data = data, let stringData = String(data: data, encoding: String.Encoding.utf8) {
                print("RefreshToken Response: \(stringData)")
            }

            self?.finish()

//            let statusCode = httpResponse.statusCode
//            switch statusCode {
//            case 200:
//                self?.finish()
//            case 401:
//                self?.callRefreshToken()
//            default:
//                self?.finish(with: UploadError.unknownResponseCode(statusCode, error))
//            }


        }
        task.resume()
    }
}
