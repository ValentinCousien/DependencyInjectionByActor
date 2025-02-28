//
//  ThemeComponent.swift
//  DependencyInjection
//
//  Created by Valentin COUSIEN on 28/02/2025.
//

import Foundation
import UIKit
import DependencyInjection

public protocol UIThemeService {
    var primaryColor: UIColor { get }
    var fontFamily: String { get }
}

public class DefaultTheme: UIThemeService {
    public var primaryColor: UIColor = .blue
    public var fontFamily: String = "Helvetica"
    
    public init() {}
}

public struct UIThemeServiceKey: MainActorInjectionKey {
    public typealias Value = UIThemeService
    
    public static var defaultValue: UIThemeService {
        DefaultTheme()
    }
}
