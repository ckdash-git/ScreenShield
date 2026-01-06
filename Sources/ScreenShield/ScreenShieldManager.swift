// ScreenShieldManager.swift
// ScreenShield
//
// Manages app-wide screen protection features including background privacy.
// Observes app lifecycle events to protect content in App Switcher.

import UIKit

/// Manages app-wide screen protection features.
///
/// `ScreenShieldManager` provides centralized control over screen protection features
/// that apply to the entire app, such as background privacy (App Switcher blurring)
/// and screenshot detection.
///
/// ## Usage
/// ```swift
/// // Enable background privacy in AppDelegate or SceneDelegate
/// ScreenShieldManager.shared.enableBackgroundPrivacy()
///
/// // Listen for screenshot attempts
/// ScreenShieldManager.shared.onScreenshotAttempt = {
///     print("Screenshot detected!")
/// }
/// ```
public final class ScreenShieldManager {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide configuration.
    public static let shared = ScreenShieldManager()
    
    // MARK: - Public Properties
    
    /// Callback invoked when the user takes a screenshot.
    /// Use this for global screenshot detection across the entire app.
    ///
    /// ## Example
    /// ```swift
    /// ScreenShieldManager.shared.onScreenshotAttempt = {
    ///     Analytics.log("screenshot_attempt")
    ///     showSecurityWarning()
    /// }
    /// ```
    public var onScreenshotAttempt: (() -> Void)? {
        didSet {
            if onScreenshotAttempt != nil {
                startScreenshotObserving()
            } else {
                stopScreenshotObserving()
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Tag used to identify the privacy blur overlay.
    private static let privacyBlurTag = 888_777_666
    
    /// Whether background privacy is enabled.
    private var isBackgroundPrivacyEnabled: Bool = false
    
    /// The blur style used for background privacy.
    private var privacyBlurStyle: UIBlurEffect.Style = .regular
    
    /// Whether app is currently in background/inactive state.
    private var isInBackground: Bool = false
    
    /// Whether screenshot observing is active.
    private var isScreenshotObservingActive: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    deinit {
        disableBackgroundPrivacy()
        stopScreenshotObserving()
    }
    
    // MARK: - Screenshot Detection
    
    /// Starts observing screenshot notifications.
    private func startScreenshotObserving() {
        guard !isScreenshotObservingActive else { return }
        isScreenshotObservingActive = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    /// Stops observing screenshot notifications.
    private func stopScreenshotObserving() {
        guard isScreenshotObservingActive else { return }
        isScreenshotObservingActive = false
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    /// Called when the user takes a screenshot.
    @objc private func userDidTakeScreenshot(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.onScreenshotAttempt?()
        }
    }
    
    // MARK: - Background Privacy API
    
    /// Enables background privacy protection.
    ///
    /// When enabled, a blur overlay is automatically added to the app's window
    /// when the app enters the background, preventing sensitive content from
    /// appearing in the iOS App Switcher.
    ///
    /// - Parameter style: The blur effect style to use. Defaults to `.regular`.
    ///
    /// ## Example
    /// ```swift
    /// // In AppDelegate's didFinishLaunchingWithOptions or SceneDelegate
    /// ScreenShieldManager.shared.enableBackgroundPrivacy()
    ///
    /// // With dark blur for dark-themed apps
    /// ScreenShieldManager.shared.enableBackgroundPrivacy(style: .dark)
    /// ```
    public func enableBackgroundPrivacy(style: UIBlurEffect.Style = .regular) {
        guard !isBackgroundPrivacyEnabled else {
            // Just update the style if already enabled
            privacyBlurStyle = style
            return
        }
        
        isBackgroundPrivacyEnabled = true
        privacyBlurStyle = style
        
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /// Disables background privacy protection.
    ///
    /// Removes the blur overlay and stops observing app lifecycle events.
    public func disableBackgroundPrivacy() {
        guard isBackgroundPrivacyEnabled else { return }
        
        isBackgroundPrivacyEnabled = false
        
        // Remove notifications
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Remove any existing blur
        removePrivacyBlur()
    }
    
    /// Returns whether background privacy is currently enabled.
    public var isBackgroundPrivacyActive: Bool {
        return isBackgroundPrivacyEnabled
    }
    
    // MARK: - Private Methods
    
    /// Called when the app is about to resign active (going to background).
    @objc private func appWillResignActive(_ notification: Notification) {
        guard isBackgroundPrivacyEnabled, !isInBackground else { return }
        isInBackground = true
        addPrivacyBlur()
    }
    
    /// Called when the app became active (returning to foreground).
    @objc private func appDidBecomeActive(_ notification: Notification) {
        guard isBackgroundPrivacyEnabled, isInBackground else { return }
        isInBackground = false
        removePrivacyBlur()
    }
    
    /// Adds the blur overlay to all windows.
    private func addPrivacyBlur() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        else {
            // Fallback for older iOS versions
            addPrivacyBlurLegacy()
            return
        }
        
        addPrivacyBlur(to: window)
    }
    
    /// Legacy method for iOS versions without scene support.
    private func addPrivacyBlurLegacy() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else {
            return
        }
        addPrivacyBlur(to: window)
    }
    
    /// Adds blur overlay to a specific window.
    private func addPrivacyBlur(to window: UIWindow) {
        // Check if blur already exists
        guard window.viewWithTag(ScreenShieldManager.privacyBlurTag) == nil else { return }
        
        let blurEffect = UIBlurEffect(style: privacyBlurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.tag = ScreenShieldManager.privacyBlurTag
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add over all content
        window.addSubview(blurView)
        
        // Animate in (quick fade for app switcher timing)
        blurView.alpha = 0
        UIView.animate(withDuration: 0.1) {
            blurView.alpha = 1
        }
    }
    
    /// Removes the blur overlay from all windows.
    private func removePrivacyBlur() {
        // Remove from all windows in all scenes
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                removePrivacyBlur(from: window)
            }
        }
        
        // Fallback for older iOS versions
        for window in UIApplication.shared.windows {
            removePrivacyBlur(from: window)
        }
    }
    
    /// Removes blur overlay from a specific window.
    private func removePrivacyBlur(from window: UIWindow) {
        guard let blurView = window.viewWithTag(ScreenShieldManager.privacyBlurTag) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            blurView.alpha = 0
        }, completion: { _ in
            blurView.removeFromSuperview()
        })
    }
}
