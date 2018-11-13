//
//  Logger.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 11/8/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import Foundation

class Logger {
    enum Tag: String {
        case healthStoreService
        case scriptMessageHandler
    }
    
    enum Level: Int, Comparable {
        case verbose
        case info
        case warnings
        case errors

        static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    private static let instance = Logger()

    #if DEBUG
    var level: Level = .verbose
    #else
    var level: Level = .warnings
    #endif

    private init() { }
    
    static func log(_ tag: Tag, verbose text: String) {
        guard Logger.instance.level >= .verbose else { return }
        print("\(tag.rawValue):\(text)")
    }
    
    static func log(_ tag: Tag, info text: String) {
        guard Logger.instance.level <= .info else { return }
        print("ℹ️\(tag.rawValue):\(text)")
    }
    
    static func log(_ tag: Tag, warning text: String) {
        guard Logger.instance.level >= .warnings else { return }
        print("⚠️\(tag.rawValue):\(text)")
    }
    
    static func log(_ tag: Tag, error text: String) {
        guard Logger.instance.level >= .errors else { return }
        print("🚨\(tag.rawValue):\(text)")
    }
}
