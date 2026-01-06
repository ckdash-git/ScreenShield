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
/// // Simple usage - detect any capture
/// ScreenRecordingObserver.shared.startObserving { isRecording in
///     if isRecording {
///         // Apply blur or hide sensitive content
///     }
/// }
///
/// // Advanced usage - differentiate between recording and external display
/// ScreenRecordingObserver.shared.startObservingWithDetail(
///     onRecordingStarted: { print("Recording started") },
///     onRecordingStopped: { print("Recording stopped") },
///     onExternalDisplayConnected: { print("AirPlay/External display connected") },
///     onExternalDisplayDisconnected: { print("External display disconnected") }
/// )
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
    
    /// Callback type for specific events (no parameters).
    public typealias EventHandler = () -> Void
    
    // MARK: - Private Properties
    
    /// The current recording state handler (simple API).
    private var stateHandler: RecordingStateHandler?
    
    /// Handler called when recording starts.
    private var onRecordingStarted: EventHandler?
    
    /// Handler called when recording stops.
    private var onRecordingStopped: EventHandler?
    
    /// Handler called when external display is connected.
    private var onExternalDisplayConnected: EventHandler?
    
    /// Handler called when external display is disconnected.
    private var onExternalDisplayDisconnected: EventHandler?
    
    /// Whether we're currently observing.
    private var isObserving: Bool = false
    
    /// Tracks the previous external display state.
    private var wasExternalDisplayConnected: Bool = false
    
    /// Tracks the previous recording state.
    private var wasRecording: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Simple Public API
    
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
        onRecordingStarted = nil
        onRecordingStopped = nil
        onExternalDisplayConnected = nil
        onExternalDisplayDisconnected = nil
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    // MARK: - Advanced Public API
    
    /// Starts observing with separate callbacks for recording and external display events.
    ///
    /// This provides more granular control over how your app responds to different
    /// types of screen capture scenarios.
    ///
    /// - Parameters:
    ///   - onRecordingStarted: Called when screen recording begins.
    ///   - onRecordingStopped: Called when screen recording ends.
    ///   - onExternalDisplayConnected: Called when an external display (AirPlay, CarPlay) connects.
    ///   - onExternalDisplayDisconnected: Called when an external display disconnects.
    public func startObservingWithDetail(
        onRecordingStarted: EventHandler? = nil,
        onRecordingStopped: EventHandler? = nil,
        onExternalDisplayConnected: EventHandler? = nil,
        onExternalDisplayDisconnected: EventHandler? = nil
    ) {
        self.onRecordingStarted = onRecordingStarted
        self.onRecordingStopped = onRecordingStopped
        self.onExternalDisplayConnected = onExternalDisplayConnected
        self.onExternalDisplayDisconnected = onExternalDisplayDisconnected
        
        // Initialize state tracking
        wasExternalDisplayConnected = hasExternalDisplay
        wasRecording = isRecordingOnly
        
        // Avoid duplicate observers
        if isObserving {
            // Fire initial events if already in a capture state
            notifyInitialState()
            return
        }
        
        isObserving = true
        
        // Register for screen capture notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCapturedDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // Register for screen connect/disconnect notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
        
        // Fire initial events
        notifyInitialState()
    }
    
    /// Returns whether the screen is currently being captured.
    ///
    /// This includes screen recording, AirPlay mirroring, and CarPlay.
    public var isScreenBeingCaptured: Bool {
        return UIScreen.main.isCaptured
    }
    
    /// Returns whether an external display is connected.
    ///
    /// This includes AirPlay mirroring, CarPlay, and physical external displays.
    public var hasExternalDisplay: Bool {
        return UIScreen.screens.count > 1
    }
    
    /// Returns whether the screen is being recorded (not including external displays).
    ///
    /// This differentiates between screen recording and AirPlay/external display mirroring.
    public var isRecordingOnly: Bool {
        return UIScreen.main.isCaptured && !hasExternalDisplay
    }
    
    /// Returns whether content is being mirrored to an external display.
    ///
    /// This is `true` when there's an external display connected AND the main screen is captured.
    public var isMirroringToExternalDisplay: Bool {
        return UIScreen.main.isCaptured && hasExternalDisplay
    }
    
    // MARK: - Private Methods
    
    /// Notifies handlers of the initial state.
    private func notifyInitialState() {
        if isRecordingOnly {
            onRecordingStarted?()
        }
        if hasExternalDisplay {
            onExternalDisplayConnected?()
        }
    }
    
    /// Called when the screen capture state changes.
    @objc private func screenCapturedDidChange(_ notification: Notification) {
        let isRecording = UIScreen.main.isCaptured
        let isExternal = hasExternalDisplay
        
        // Notify on main thread to ensure UI updates are safe
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Simple API handler
            self.stateHandler?(isRecording)
            
            // Advanced API handlers
            let isNowRecording = isRecording && !isExternal
            
            // Check if recording state changed
            if isNowRecording && !self.wasRecording {
                self.onRecordingStarted?()
            } else if !isNowRecording && self.wasRecording {
                self.onRecordingStopped?()
            }
            
            self.wasRecording = isNowRecording
        }
    }
    
    /// Called when a screen is connected.
    @objc private func screenDidConnect(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !self.wasExternalDisplayConnected && self.hasExternalDisplay {
                self.wasExternalDisplayConnected = true
                self.onExternalDisplayConnected?()
            }
        }
    }
    
    /// Called when a screen is disconnected.
    @objc private func screenDidDisconnect(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.wasExternalDisplayConnected && !self.hasExternalDisplay {
                self.wasExternalDisplayConnected = false
                self.onExternalDisplayDisconnected?()
            }
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
