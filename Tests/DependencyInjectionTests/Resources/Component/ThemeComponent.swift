//
//  ThemeComponen.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 28/02/2025.
//

import DependencyInjection

// Non-sendable example (MainActor only)
@MainActor
public final class ThemeComponent {
    @MainActorInjected(UIThemeServiceKey.self)
    private var theme: UIThemeService
    
    public init() {}
    
    public func updateUI() {
        // Access non-sendable properties safely on the main actor
        let color = theme.primaryColor
        let font = theme.fontFamily
        print("Updating UI with color: \(color) and font: \(font)")
    }
}
