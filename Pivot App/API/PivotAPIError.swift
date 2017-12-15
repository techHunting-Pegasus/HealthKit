//
//  APIError.swift
//  Pivot
//
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case badRequestBody(error: Error)
}
