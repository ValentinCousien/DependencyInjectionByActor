//
//  DependencyInjection.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import Foundation

/// Protocol defining a dependency injection key
public protocol InjectionKey: Sendable {
    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value: Sendable
    
    /// The default value for the dependency
    static var defaultValue: Self.Value { get }
}

/// Actor for thread-safe dependency storage
public actor DependencyStorage {
    public static let shared = DependencyStorage()
    private var storage: [String: Any] = [:]
    
    private init() {}
    
    func getValue<K: InjectionKey>(for keyType: K.Type) -> K.Value {
        let key = String(describing: keyType)
        if let value = storage[key] as? K.Value {
            return value
        } else {
            let defaultValue = K.defaultValue
            storage[key] = defaultValue
            return defaultValue
        }
    }
    
    func setValue<K: InjectionKey>(_ value: K.Value, for keyType: K.Type) {
        let key = String(describing: keyType)
        storage[key] = value
    }
    
    public func resetAllValues() {
        // Clear the entire storage dictionary
        storage.removeAll()
    }
}

/// Provides access to injected dependencies using type-based lookup
public struct InjectedValues: Sendable {
    /// A static function for getting values - must be called with 'await'
    public static func value<K: InjectionKey>(for key: K.Type) async -> K.Value {
        await DependencyStorage.shared.getValue(for: key)
    }
    
    /// A static function for setting values - must be called with 'await'
    public static func setValue<K: InjectionKey>(_ newValue: K.Value, for key: K.Type) async {
        await DependencyStorage.shared.setValue(newValue, for: key)
    }
}

/// Nonisolated wrapper for synchronous access
public extension InjectedValues {
    /// Synchronously get a value (blocks current thread briefly)
    static func valueSync<K: InjectionKey>(for key: K.Type) -> K.Value {
        // Use a semaphore to block until we get the value from the actor
        let semaphore = DispatchSemaphore(value: 0)
        var result: K.Value = key.defaultValue
        
        Task {
            result = await DependencyStorage.shared.getValue(for: key)
            semaphore.signal()
        }
        
        // Wait with timeout to avoid deadlocks
        let waitResult = semaphore.wait(timeout: .now() + 0.5)
        
        // If timeout occurred, return default value
        if waitResult == .timedOut {
            return key.defaultValue
        }
        
        return result
    }
    
    /// Synchronously set a value (fire and forget)
    static func setValueSync<K: InjectionKey>(_ newValue: K.Value, for key: K.Type) {
        Task {
            await DependencyStorage.shared.setValue(newValue, for: key)
        }
    }
    
    /// A static subscript for synchronous access
    static subscript<K>(key: K.Type) -> K.Value where K: InjectionKey {
        get { valueSync(for: key) }
        set { setValueSync(newValue, for: key) }
    }
}

/// Property wrapper for injected dependencies (synchronous access)
@propertyWrapper
public struct Injected<K: InjectionKey>: Sendable {
    public var wrappedValue: K.Value {
        get { InjectedValues[K.self] }
        set { InjectedValues[K.self] = newValue }
    }
    
    public init(_ keyType: K.Type = K.self) {}
}

/// Property wrapper for injected dependencies with async access
@propertyWrapper
public struct AsyncInjected<K: InjectionKey>: Sendable {
    public var wrappedValue: K.Value {
        get { InjectedValues[K.self] } // Sync fallback for property access
        set { InjectedValues[K.self] = newValue }
    }
    
    public var projectedValue: AsyncInjected<K> {
        return self
    }
    
    // These provide the proper async access
    public func get() async -> K.Value {
        await InjectedValues.value(for: K.self)
    }
    
    public func set(_ newValue: K.Value) async {
        await InjectedValues.setValue(newValue, for: K.self)
    }
    
    public init(_ keyType: K.Type = K.self) {}
}
