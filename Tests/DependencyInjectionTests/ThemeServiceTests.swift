import Testing
import Foundation
import UIKit
import DependencyInjection

// MARK: - Mock UIThemeService Implementation
final class MockTheme: UIThemeService {
    var primaryColor: UIColor
    var fontFamily: String
    
    init(primaryColor: UIColor = .red, fontFamily: String = "Roboto") {
        self.primaryColor = primaryColor
        self.fontFamily = fontFamily
    }
}

// MARK: - Testable ThemeComponent with Inspection
@MainActor
final class TestableThemeComponent {
    @MainActorInjected(UIThemeServiceKey.self)
    private var theme: UIThemeService
    
    var lastUsedColor: UIColor?
    var lastUsedFont: String?
    
    init() {}
    
    func updateUI() {
        // Store the values for test inspection instead of printing
        lastUsedColor = theme.primaryColor
        lastUsedFont = theme.fontFamily
    }
}

// MARK: - Tests for ThemeComponent and DefaultTheme
@Suite(.serialized) struct ThemeServiceTests {
    
    @Test("DefaultTheme has correct default values")
    func testDefaultThemeValues() {
        let defaultTheme = DefaultTheme()
        
        #expect(defaultTheme.primaryColor == .blue)
        #expect(defaultTheme.fontFamily == "Helvetica")
    }
    
    @Test("ThemeComponent uses injected theme")
    func testThemeComponentUsesInjectedTheme() async {
        // Just use @MainActor isolation directly
        @MainActor func performTest() async {
            // Test code
            let mockTheme = MockTheme(primaryColor: .green, fontFamily: "Arial")
            InjectedValues[UIThemeServiceKey.self] = mockTheme
            
            let component = TestableThemeComponent()
            component.updateUI()
            
            #expect(component.lastUsedColor == .green)
            #expect(component.lastUsedFont == "Arial")
        }
        
        await performTest()
    }
    
    @Test("ThemeComponent can change theme at runtime")
    func testThemeComponentCanChangeTheme() async {
        @MainActor func performTest() async {// Given
            let initialTheme = MockTheme(primaryColor: .yellow, fontFamily: "Times")
            InjectedValues[UIThemeServiceKey.self] = initialTheme
            let component = TestableThemeComponent()
            component.updateUI()
            
            // Check initial state
            #expect(component.lastUsedColor == .yellow)
            #expect(component.lastUsedFont == "Times")
            
            // When
            let newTheme = MockTheme(primaryColor: .purple, fontFamily: "Comic Sans")
            InjectedValues[UIThemeServiceKey.self] = newTheme
            component.updateUI()
            
            // Then
            #expect(component.lastUsedColor == .purple)
            #expect(component.lastUsedFont == "Comic Sans")
        }
        
        
        await performTest()
    }
    
    @Test("MainActorDependencyStorage properly stores theme")
    func testMainActorDependencyStorageWithTheme() async {
        @MainActor func performTest() async {
            // Given
            let customTheme = MockTheme(primaryColor: .brown, fontFamily: "Georgia")
            
            // When
            InjectedValues.setMainActorValue(customTheme, for: UIThemeServiceKey.self)
            let retrievedTheme = InjectedValues.mainActorValue(for: UIThemeServiceKey.self)
            
            // Then
            #expect(retrievedTheme is MockTheme)
            if let mockTheme = retrievedTheme as? MockTheme {
                #expect(mockTheme.primaryColor == .brown)
                #expect(mockTheme.fontFamily == "Georgia")
            }
        }
        
        await performTest()
    }
}

// Helper extension for UIColor comparison in tests
extension UIColor {
    static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        lhs.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        rhs.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
    }
}
