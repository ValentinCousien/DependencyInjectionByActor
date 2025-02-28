//
//  LoggingService.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import DependencyInjection

// 1. Define your service protocols
protocol LoggingService: Sendable {
    func log(_ message: String)
}

// 2. Create concrete implementations
struct ConsoleLogger: LoggingService {
    public init() {}
    
    public func log(_ message: String) {
        print("LOG: \(message)")
    }
}

// 3. Define an injection key
struct LoggingServiceKey: SendableInjectionKey {
    public typealias Value = any LoggingService
    
    public static var defaultValue: any LoggingService {
        ConsoleLogger()
    }
}
