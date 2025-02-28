//
//  AsyncComponentTests.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import Testing
import DependencyInjection

// MARK: - Async Component Tests
@Suite(.serialized) struct ComponentsTests {
    @Test("AsyncComponent logs message correctly")
    func testDoSomethingLogsAsynchronousMessage() async {
        // Given
        await resetAllDependencies()
        let mockLogger = MockLogger()
        await InjectedValues.setValue(mockLogger, for: LoggingServiceKey.self)
        let component = AsyncComponent()
        
        // When
        await component.doSomething()
        
        // Then
        let count = await mockLogger.messageCount()
        let message = await mockLogger.firstMessage()
        #expect(count == 1)
        #expect(message == "Something was done asynchronously!")
    }
    
    @Test("AsyncComponent handles failed logging")
    func testAsyncFailedLogging() async {
        // Given
        await resetAllDependencies()
        let mockLogger = MockLogger()
        await mockLogger.setShouldLogSuccessfully(false)
        await InjectedValues.setValue(mockLogger, for: LoggingServiceKey.self)
        let component = AsyncComponent()
        
        // When
        await component.doSomething()
        
        // Then
        let isEmpty = await mockLogger.isEmpty()
        #expect(isEmpty)
    }
    
    @Test("SyncComponent logs message correctly")
    func testDoSomethingLogsSynchronousMessage() async {
        // Given
        await resetAllDependencies()
        let mockLogger = MockLogger()
        await InjectedValues.setValue(mockLogger, for: LoggingServiceKey.self)
        let component = SyncComponent()
        
        // When
        component.doSomething()
        
        // Wait for the log operation to complete
        await mockLogger.waitForLogCompletion()
        
        // Then
        let count = await mockLogger.messageCount()
        let message = await mockLogger.firstMessage()
        #expect(count == 1)
        #expect(message == "Something was done synchronously!")
    }
    
    @Test("SyncComponent handles failed logging")
    func testFailedLogging() async {
        // Given
        await resetAllDependencies()
        let mockLogger = MockLogger()
        await mockLogger.setShouldLogSuccessfully(false)
        await InjectedValues.setValue(mockLogger, for: LoggingServiceKey.self)
        let component = SyncComponent()
        
        // When
        component.doSomething()
        
        // Wait for the log operation to complete
        await mockLogger.waitForLogCompletion()
        
        // Then
        let isEmpty = await mockLogger.isEmpty()
        #expect(isEmpty)
    }
    
    // Helper function to reset all dependencies
    func resetAllDependencies() async {
        // Reset the dependency injection storage
        await DependencyStorage.shared.resetAllValues()
    }
}
