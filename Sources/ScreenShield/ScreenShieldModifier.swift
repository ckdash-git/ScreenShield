// ScreenShieldModifier.swift
// ScreenShield
//
// A ViewModifier that wraps any SwiftUI view with screenshot protection.
// Provides a convenient .protectScreenshot() modifier syntax.

import SwiftUI

/// A ViewModifier that adds screenshot protection to any SwiftUI view.
///
/// This modifier wraps the view in a `ScreenShieldView` to prevent the content
/// from appearing in screenshots and screen recordings.
///
/// ## Usage
/// ```swift
/// Text("Secret")
///     .protectScreenshot()
///
/// // With conditional protection
/// Text("Maybe Secret")
///     .protectScreenshot(when: isSecretMode)
/// ```
@available(iOS 13.0, *)
public struct ScreenShieldModifier: ViewModifier {
    
    /// Whether protection is enabled.
    private let isProtected: Bool
    
    /// Creates a new screen shield modifier.
    ///
    /// - Parameter isProtected: Whether protection is enabled. Defaults to `true`.
    public init(isProtected: Bool = true) {
        self.isProtected = isProtected
    }
    
    public func body(content: Content) -> some View {
        ScreenShieldView(isProtected: isProtected) {
            content
        }
    }
}

// MARK: - View Extension

@available(iOS 13.0, *)
public extension View {
    
    /// Protects this view from appearing in screenshots and screen recordings.
    ///
    /// When applied, the view's content will be hidden (appear blank) when the
    /// user takes a screenshot or records the screen.
    ///
    /// - Returns: A view with screenshot protection applied.
    ///
    /// ## Example
    /// ```swift
    /// VStack {
    ///     Text("Account Number")
    ///     Text("1234-5678-9012")
    ///         .protectScreenshot()
    /// }
    /// ```
    func protectScreenshot() -> some View {
        modifier(ScreenShieldModifier(isProtected: true))
    }
    
    /// Conditionally protects this view from screenshots and screen recordings.
    ///
    /// - Parameter condition: When `true`, protection is applied. When `false`,
    ///   the view renders normally and can be captured.
    /// - Returns: A view with conditional screenshot protection.
    ///
    /// ## Example
    /// ```swift
    /// Text("Sensitive Data")
    ///     .protectScreenshot(when: userSettings.hideInScreenshots)
    /// ```
    func protectScreenshot(when condition: Bool) -> some View {
        modifier(ScreenShieldModifier(isProtected: condition))
    }
}
