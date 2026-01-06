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
/// // Always protect
/// Text("Secret")
///     .protectScreenshot()
///
/// // Server-controlled protection
/// Text("Dynamic Secret")
///     .protectScreenshot(serverConfig.screenshotProtectionEnabled)
///
/// // Conditional with named parameter
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
    /// - Parameter isEnabled: Whether protection is enabled. Defaults to `true`.
    ///   Pass `false` to disable protection (e.g., based on server configuration).
    /// - Returns: A view with screenshot protection applied when enabled.
    ///
    /// ## Example
    /// ```swift
    /// // Always protect
    /// Text("1234-5678-9012")
    ///     .protectScreenshot()
    ///
    /// // Server-controlled protection
    /// Text("Sensitive Data")
    ///     .protectScreenshot(appConfig.isScreenshotProtectionEnabled)
    ///
    /// // Disabled protection
    /// Text("Public Info")
    ///     .protectScreenshot(false)
    /// ```
    func protectScreenshot(_ isEnabled: Bool = true) -> some View {
        modifier(ScreenShieldModifier(isProtected: isEnabled))
    }
    
    /// Conditionally protects this view from screenshots and screen recordings.
    ///
    /// This is an alternative syntax using a named parameter for clarity.
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
    
    /// Registers a callback to be invoked when the user takes a screenshot.
    ///
    /// This modifier enables global screenshot detection for the app.
    /// Use it to log attempts, show warnings, or take other protective actions.
    ///
    /// - Parameter action: The callback to invoke when a screenshot is taken.
    /// - Returns: The modified view.
    ///
    /// ## Example
    /// ```swift
    /// ContentView()
    ///     .onScreenshotAttempt {
    ///         showSecurityWarning = true
    ///         Analytics.log("screenshot_attempted")
    ///     }
    /// ```
    func onScreenshotAttempt(_ action: @escaping () -> Void) -> some View {
        self.onAppear {
            ScreenShieldManager.shared.onScreenshotAttempt = action
        }
        .onDisappear {
            ScreenShieldManager.shared.onScreenshotAttempt = nil
        }
    }
}

// MARK: - Background Privacy Modifier

/// A ViewModifier that enables background privacy protection.
///
/// This modifier automatically enables/disables background privacy when the view appears/disappears.
@available(iOS 13.0, *)
public struct BackgroundPrivacyModifier: ViewModifier {
    
    /// The blur style to use.
    private let style: UIBlurEffect.Style
    
    /// Whether background privacy is enabled.
    private let isEnabled: Bool
    
    /// Creates a new background privacy modifier.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether to enable background privacy. Defaults to `true`.
    ///   - style: The blur effect style. Defaults to `.regular`.
    public init(isEnabled: Bool = true, style: UIBlurEffect.Style = .regular) {
        self.isEnabled = isEnabled
        self.style = style
    }
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                if isEnabled {
                    ScreenShieldManager.shared.enableBackgroundPrivacy(style: style)
                }
            }
            .onDisappear {
                if isEnabled {
                    ScreenShieldManager.shared.disableBackgroundPrivacy()
                }
            }
    }
}

// MARK: - Background Privacy View Extension

@available(iOS 13.0, *)
public extension View {
    
    /// Enables background privacy protection for the app.
    ///
    /// When the app enters the background, a blur overlay is applied to hide
    /// sensitive content from the iOS App Switcher.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether to enable background privacy. Defaults to `true`.
    ///   - style: The blur effect style. Defaults to `.regular`.
    /// - Returns: A view with background privacy enabled.
    ///
    /// ## Example
    /// ```swift
    /// ContentView()
    ///     .enableBackgroundPrivacy()
    ///
    /// // With dark blur
    /// ContentView()
    ///     .enableBackgroundPrivacy(style: .dark)
    ///
    /// // Conditionally enabled
    /// ContentView()
    ///     .enableBackgroundPrivacy(appSettings.privacyEnabled, style: .regular)
    /// ```
    func enableBackgroundPrivacy(
        _ isEnabled: Bool = true,
        style: UIBlurEffect.Style = .regular
    ) -> some View {
        modifier(BackgroundPrivacyModifier(isEnabled: isEnabled, style: style))
    }
}

