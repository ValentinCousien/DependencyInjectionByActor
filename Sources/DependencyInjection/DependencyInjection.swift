//
//  DependencyInjection.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import Foundation
import Foundation

/// Protocol for sendable injection keys
public protocol SendableInjectionKey: Sendable {
    associatedtype Value: Sendable
    static var defaultValue: Self.Value { get }
}

/// Protocol for non-sendable injection keys (must be used on main actor)
public protocol MainActorInjectionKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
}

/// Actor for thread-safe dependency storage of Sendable values
public actor DependencyStorage {
    public static let shared = DependencyStorage()
    private var storage: [String: Any] = [:]
    
    private init() {}
    
    func getValue<K: SendableInjectionKey>(for keyType: K.Type) -> K.Value {
        let key = String(describing: keyType)
        if let value = storage[key] as? K.Value {
            return value
        } else {
            let defaultValue = K.defaultValue
            storage[key] = defaultValue
            return defaultValue
        }
    }
    
    func setValue<K: SendableInjectionKey>(_ value: K.Value, for keyType: K.Type) {
        let key = String(describing: keyType)
        storage[key] = value
    }
    
    public func resetAllValues() {
        // Clear the entire storage dictionary
        storage.removeAll()
    }
}

/// Class for main-actor isolated storage of non-Sendable values
@MainActor
public final class MainActorDependencyStorage {
    public static let shared = MainActorDependencyStorage()
    private var storage: [String: Any] = [:]
    
    private init() {}
    
    func getValue<K: MainActorInjectionKey>(for keyType: K.Type) -> K.Value {
        let key = String(describing: keyType)
        if let value = storage[key] as? K.Value {
            return value
        } else {
            let defaultValue = K.defaultValue
            storage[key] = defaultValue
            return defaultValue
        }
    }
    
    func setValue<K: MainActorInjectionKey>(_ value: K.Value, for keyType: K.Type) {
        let key = String(describing: keyType)
        storage[key] = value
    }
    
    public func resetAllValues() {
        // Clear the entire storage dictionary
        storage.removeAll()
    }
}

/// Access point for injected dependencies
public struct InjectedValues {
    // MARK: - Sendable Values API
    
    /// Get a sendable value asynchronously
    public static func value<K: SendableInjectionKey>(for key: K.Type) async -> K.Value {
        await DependencyStorage.shared.getValue(for: key)
    }
    
    /// Set a sendable value asynchronously
    public static func setValue<K: SendableInjectionKey>(_ newValue: K.Value, for key: K.Type) async {
        await DependencyStorage.shared.setValue(newValue, for: key)
    }
    
    /// Get a sendable value synchronously
    public static func valueSync<K: SendableInjectionKey>(for key: K.Type) -> K.Value {
        let semaphore = DispatchSemaphore(value: 0)
        var result: K.Value = key.defaultValue
        
        Task {
            result = await DependencyStorage.shared.getValue(for: key)
            semaphore.signal()
        }
        
        let waitResult = semaphore.wait(timeout: .now() + 0.5)
        if waitResult == .timedOut {
            return key.defaultValue
        }
        
        return result
    }
    
    /// Set a sendable value synchronously (fire and forget)
    public static func setValueSync<K: SendableInjectionKey>(_ newValue: K.Value, for key: K.Type) {
        Task {
            await DependencyStorage.shared.setValue(newValue, for: key)
        }
    }
    
    /// Subscribe to sendable values
    public static subscript<K>(key: K.Type) -> K.Value where K: SendableInjectionKey {
        get { valueSync(for: key) }
        set { setValueSync(newValue, for: key) }
    }
    
    // MARK: - Non-Sendable Values API (MainActor only)
    
    /// Get a non-sendable value (MainActor only)
    @MainActor
    public static func mainActorValue<K: MainActorInjectionKey>(for key: K.Type) -> K.Value {
        MainActorDependencyStorage.shared.getValue(for: key)
    }
    
    /// Set a non-sendable value (MainActor only)
    @MainActor
    public static func setMainActorValue<K: MainActorInjectionKey>(_ newValue: K.Value, for key: K.Type) {
        MainActorDependencyStorage.shared.setValue(newValue, for: key)
    }
    
    /// Access non-sendable values (MainActor only)
    @MainActor
    public static subscript<K>(key: K.Type) -> K.Value where K: MainActorInjectionKey {
        get { mainActorValue(for: key) }
        set { setMainActorValue(newValue, for: key) }
    }
}

// MARK: - Property Wrappers

/// Property wrapper for injected sendable dependencies (synchronous access)
@propertyWrapper
public struct Injected<K: SendableInjectionKey>: Sendable {
    public var wrappedValue: K.Value {
        get { InjectedValues[K.self] }
        set { InjectedValues[K.self] = newValue }
    }
    
    public init(_ keyType: K.Type = K.self) {}
}

/// Property wrapper for injected sendable dependencies (async access)
@propertyWrapper
public struct AsyncInjected<K: SendableInjectionKey>: Sendable {
    public var wrappedValue: K.Value {
        get { InjectedValues[K.self] }
        set { InjectedValues[K.self] = newValue }
    }
    
    public var projectedValue: AsyncInjected<K> {
        return self
    }
    
    public func get() async -> K.Value {
        await InjectedValues.value(for: K.self)
    }
    
    public func set(_ newValue: K.Value) async {
        await InjectedValues.setValue(newValue, for: K.self)
    }
    
    public init(_ keyType: K.Type = K.self) {}
}

/// Property wrapper for non-sendable dependencies (MainActor only)
@propertyWrapper
public struct MainActorInjected<K: MainActorInjectionKey> {
    @MainActor
    public var wrappedValue: K.Value {
        get { InjectedValues[K.self] }
        set { InjectedValues[K.self] = newValue }
    }
    
    public init(_ keyType: K.Type = K.self) {}
}
