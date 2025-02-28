//
//  SyncComponent.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 27/02/2025.
//

import DependencyInjection

final class SyncComponent {
    @Injected(LoggingServiceKey.self)
    private var logger: LoggingService
    
    public func doSomething() {
        logger.log("Something was done synchronously!")
    }
}
