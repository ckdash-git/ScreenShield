// ScreenShieldView.swift
// ScreenShield
//
// SwiftUI wrapper around ShieldView using UIViewRepresentable.
// Allows SwiftUI developers to easily protect their content.

import SwiftUI
import UIKit

/// A SwiftUI view that protects its content from screenshots and screen recordings.
///
/// `ScreenShieldView` wraps the UIKit `ShieldView` to provide screenshot protection
/// for SwiftUI content. Any content placed inside this view will be hidden when
/// the user attempts to take a screenshot or record the screen.
///
/// ## Usage
/// ```swift
/// ScreenShieldView {
///     VStack {
///         Text("Sensitive Information")
///         Image(systemName: "lock.fill")
///     }
/// }
/// ```
///
/// - Important: This technique relies on undocumented iOS behavior involving
///   `isSecureTextEntry`. Test thoroughly with each iOS release.
@available(iOS 13.0, *)
public struct ScreenShieldView<Content: View>: UIViewRepresentable {
    
    /// The SwiftUI content to protect.
    private let content: Content
    
    /// Whether protection is enabled.
    private let isProtected: Bool
    
    /// Callback invoked when the user takes a screenshot.
    private let onScreenshotAttempt: (() -> Void)?
    
    /// Creates a new screen shield view with the given content.
    ///
    /// - Parameters:
    ///   - isProtected: Whether protection is enabled. Defaults to `true`.
    ///   - onScreenshotAttempt: Optional callback when a screenshot is taken.
    ///   - content: A view builder closure that creates the content to protect.
    public init(
        isProtected: Bool = true,
        onScreenshotAttempt: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isProtected = isProtected
        self.onScreenshotAttempt = onScreenshotAttempt
        self.content = content()
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> UIView {
        // Create container view to hold everything
        let containerView = SafeAreaObservingView()
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = false
        
        // Propagate safe area insets to the hosting controller
        // This is necessary because views inside the secure text field hierarchy
        // do not strictly inherit safe area insets from the window.
        let coordinator = context.coordinator
        containerView.onSafeAreaInsetsDidChange = { [weak coordinator] insets in
            coordinator?.hostingController?.additionalSafeAreaInsets = insets
        }
        
        // Create ShieldView
        let shieldView = ShieldView()
        shieldView.translatesAutoresizingMaskIntoConstraints = false
        shieldView.clipsToBounds = false
        containerView.addSubview(shieldView)
        
        // Create hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Store references in coordinator
        context.coordinator.shieldView = shieldView
        context.coordinator.hostingController = hostingController
        
        // Set screenshot callback
        shieldView.onScreenshotAttempt = onScreenshotAttempt
        
        // Add hosting view to shield's content view
        shieldView.addProtectedContent(hostingController.view)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Shield fills container
            shieldView.topAnchor.constraint(equalTo: containerView.topAnchor),
            shieldView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            shieldView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Hosting view fills shield's content view
            hostingController.view.topAnchor.constraint(equalTo: shieldView.contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: shieldView.contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: shieldView.contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: shieldView.contentView.bottomAnchor)
        ])
        
        // Set initial protection state
        shieldView.setProtected(isProtected)
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update protection state
        context.coordinator.shieldView?.setProtected(isProtected)
        
        // Update SwiftUI content
        context.coordinator.hostingController?.rootView = content
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    /// Coordinator that holds references to UIKit views.
    public class Coordinator {
        var shieldView: ShieldView?
        var hostingController: UIHostingController<Content>?
    }
}

// MARK: - Preview Provider

#if DEBUG
@available(iOS 13.0, *)
struct ScreenShieldView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenShieldView {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Protected Content")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This content is hidden from screenshots")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
#endif

// MARK: - Internal Helpers

private class SafeAreaObservingView: UIView {
    var onSafeAreaInsetsDidChange: ((UIEdgeInsets) -> Void)?
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        onSafeAreaInsetsDidChange?(safeAreaInsets)
    }
}
