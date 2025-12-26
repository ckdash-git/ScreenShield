// ScreenShield.swift
// ScreenShield
//
// Main module file that provides public exports and convenience APIs.
// This is the primary entry point for the ScreenShield library.

import UIKit
import SwiftUI

// MARK: - Module Documentation

/// ScreenShield is a Swift package that helps protect sensitive content from
/// screenshots and screen recordings in iOS applications.
///
/// ## Overview
/// This package provides two main approaches to content protection:
///
/// 1. **Secure Field Technique**: Uses `UITextField`'s `isSecureTextEntry` property
///    to hide content from screenshots. This is the primary protection method.
///
/// 2. **Screen Recording Detection**: Listens for `UIScreen.capturedDidChangeNotification`
///    to detect screen recording and apply additional protection (like blur).
///
/// ## UIKit Usage
/// ```swift
/// import ScreenShield
///
/// let shieldView = ShieldView()
/// view.addSubview(shieldView)
///
/// let sensitiveLabel = UILabel()
/// sensitiveLabel.text = "Secret"
/// shieldView.addProtectedContent(sensitiveLabel)
/// ```
///
/// ## SwiftUI Usage
/// ```swift
/// import ScreenShield
///
/// Text("Secret Information")
///     .protectScreenshot()
///
/// // Or wrap multiple views
/// ScreenShieldView {
///     VStack {
///         Text("Protected")
///         Image(systemName: "lock")
///     }
/// }
/// ```
///
/// ## Important Disclaimer
/// This package uses an architectural workaround based on the behavior of
/// `UITextField`'s `isSecureTextEntry` property. While this technique has
/// been used successfully in production apps, it relies on undocumented
/// iOS behavior that could change in future iOS versions.
///
/// - Note: Always test your implementation with new iOS releases.

// MARK: - Re-exports

// All public types are automatically exported through their respective files:
// - ShieldView (UIKit)
// - ScreenShieldView (SwiftUI)
// - ScreenShieldModifier (SwiftUI ViewModifier)
// - ScreenRecordingObserver (Recording detection)

// MARK: - Version Information

/// The current version of the ScreenShield library.
public struct ScreenShieldInfo {
    /// The current semantic version of the library.
    public static let version = "1.0.0"
    
    /// The minimum iOS version supported.
    public static let minimumIOSVersion = "13.0"
    
    private init() {}
}
