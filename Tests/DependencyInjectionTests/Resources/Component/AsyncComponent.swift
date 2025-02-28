//
//  AsyncComponent.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import DependencyInjection

final class AsyncComponent {
    @AsyncInjected(LoggingServiceKey.self)
    private var logger: any LoggingService
    
    public func doSomething() async {
        let logger = await $logger.get() // Proper async access
        logger.log("Something was done asynchronously!")
        
        // If you're using an actor-based logger, you need to ensure the log completes
        if let mockLogger = logger as? MockLogger {
            await mockLogger.waitForLogCompletion()
        }
    }
}
