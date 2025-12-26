// ScreenRecordingObserver.swift
// ScreenShield
//
// Observes screen recording state changes and notifies listeners.
// This serves as a backup detection mechanism to the secure field technique.
//
// How it works:
// iOS provides UIScreen.capturedDidChangeNotification to detect when
// screen recording or mirroring starts/stops. We use this to apply
// additional protection (like blur) when recording is detected.

import UIKit

/// Observes screen recording and mirroring state changes.
///
/// This class provides a callback-based mechanism to detect when the user
/// starts or stops screen recording or AirPlay mirroring. Use this as a
/// backup protection mechanism alongside `ShieldView`.
///
/// ## Usage
/// ```swift
/// ScreenRecordingObserver.shared.startObserving { isRecording in
///     if isRecording {
///         // Apply blur or hide sensitive content
///     } else {
///         // Remove blur or show content
///     }
/// }
/// ```
///
/// - Important: Always call `stopObserving()` when you no longer need
///   to monitor recording state, such as in `deinit` or when the view disappears.
public final class ScreenRecordingObserver {
    
    // MARK: - Singleton
    
    /// Shared instance for convenience.
    /// You can also create your own instances if needed.
    public static let shared = ScreenRecordingObserver()
    
    // MARK: - Types
    
    /// Callback type for recording state changes.
    /// - Parameter isRecording: `true` if screen is being captured, `false` otherwise.
    public typealias RecordingStateHandler = (_ isRecording: Bool) -> Void
    
    // MARK: - Private Properties
    
    /// The current recording state handler.
    private var stateHandler: RecordingStateHandler?
    
    /// Whether we're currently observing.
    private var isObserving: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Public API
    
    /// Starts observing screen recording state changes.
    ///
    /// The handler will be called immediately with the current state,
    /// and then again whenever the state changes.
    ///
    /// - Parameter handler: Closure called when recording state changes.
    public func startObserving(handler: @escaping RecordingStateHandler) {
        // Store the handler
        stateHandler = handler
        
        // Avoid duplicate observers
        if isObserving {
            // Just call with current state
            handler(isScreenBeingCaptured)
            return
        }
        
        isObserving = true
        
        // Register for the notification
        // This notification fires when screen recording or mirroring starts/stops
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCapturedDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // Call handler immediately with current state
        handler(isScreenBeingCaptured)
    }
    
    /// Stops observing screen recording state changes.
    ///
    /// Call this when you no longer need to monitor recording state.
    public func stopObserving() {
        guard isObserving else { return }
        
        isObserving = false
        stateHandler = nil
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
    
    /// Returns whether the screen is currently being captured.
    ///
    /// This includes screen recording, AirPlay mirroring, and CarPlay.
    public var isScreenBeingCaptured: Bool {
        return UIScreen.main.isCaptured
    }
    
    // MARK: - Private Methods
    
    /// Called when the screen capture state changes.
    @objc private func screenCapturedDidChange(_ notification: Notification) {
        let isRecording = UIScreen.main.isCaptured
        
        // Notify on main thread to ensure UI updates are safe
        DispatchQueue.main.async { [weak self] in
            self?.stateHandler?(isRecording)
        }
    }
}

// MARK: - UIView Extension for Blur Protection

public extension UIView {
    
    /// Tag used to identify the recording blur overlay.
    private static let recordingBlurTag = 999_888_777
    
    /// Applies a blur overlay to this view when screen recording is detected.
    ///
    /// This is a convenience method that automatically adds/removes a blur
    /// effect based on recording state.
    ///
    /// - Parameters:
    ///   - observer: The observer instance to use. Defaults to shared instance.
    ///   - style: The blur style to apply. Defaults to `.regular`.
    func enableRecordingBlur(
        using observer: ScreenRecordingObserver = .shared,
        style: UIBlurEffect.Style = .regular
    ) {
        observer.startObserving { [weak self] isRecording in
            guard let self = self else { return }
            
            if isRecording {
                self.addRecordingBlurOverlay(style: style)
            } else {
                self.removeRecordingBlurOverlay()
            }
        }
    }
    
    /// Adds a blur overlay to the view.
    private func addRecordingBlurOverlay(style: UIBlurEffect.Style) {
        // Check if blur already exists
        guard viewWithTag(UIView.recordingBlurTag) == nil else { return }
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.tag = UIView.recordingBlurTag
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        
        addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Animate the blur in
        blurView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            blurView.alpha = 1
        }
    }
    
    /// Removes the blur overlay from the view.
    private func removeRecordingBlurOverlay() {
        guard let blurView = viewWithTag(UIView.recordingBlurTag) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            blurView.alpha = 0
        }, completion: { _ in
            blurView.removeFromSuperview()
        })
    }
}
