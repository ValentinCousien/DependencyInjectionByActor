//
//  Untitled.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import Foundation

actor MockLogger: LoggingService {
    private(set) var loggedMessages: [String] = []
    var shouldLogSuccessfully = true
    
    // Use a completion flag instead of continuations
    private var logCompleted = false
    
    nonisolated func log(_ message: String) {
        print("MockLogger: log called with message: \(message)")
        Task {
            print("MockLogger: Task started for message: \(message)")
            if await self.shouldLogSuccessfully {
                print("MockLogger: Should log successfully, appending message")
                await self.appendMessage(message)
            } else {
                print("MockLogger: Should not log successfully, skipping")
            }
            print("MockLogger: Marking log as completed")
            await self.markLogCompleted()
        }
    }
    
    func appendMessage(_ message: String) {
        loggedMessages.append(message)
    }
    
    func markLogCompleted() {
        logCompleted = true
    }
    
    func waitForLogCompletion() async {
        // Add a timeout to prevent infinite waiting
        let startTime = Date()
        while !logCompleted && Date().timeIntervalSince(startTime) < 1.0 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Reset for next time
        logCompleted = false
    }
    
    func setShouldLogSuccessfully(_ value: Bool) {
        shouldLogSuccessfully = value
    }
}

// MARK: - Test Helper Extensions for MockLogger
// This assumes the actor-based MockLogger implementation

extension MockLogger {
    func messageCount() -> Int {
        return loggedMessages.count
    }
    
    func isEmpty() -> Bool {
        return loggedMessages.isEmpty
    }
    
    func firstMessage() -> String? {
        return loggedMessages.first
    }
}
