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
    
    /// Creates a new screen shield view with the given content.
    ///
    /// - Parameters:
    ///   - isProtected: Whether protection is enabled. Defaults to `true`.
    ///   - content: A view builder closure that creates the content to protect.
    public init(
        isProtected: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.isProtected = isProtected
        self.content = content()
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> ShieldView {
        let shieldView = ShieldView()
        
        // Create a hosting controller for the SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Store the hosting controller in the coordinator to prevent deallocation
        context.coordinator.hostingController = hostingController
        
        // Add the hosting controller's view to the shield
        shieldView.addProtectedContent(hostingController.view)
        
        // Constrain the hosting view to fill the shield's content view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: shieldView.contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: shieldView.contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: shieldView.contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: shieldView.contentView.bottomAnchor)
        ])
        
        return shieldView
    }
    
    public func updateUIView(_ uiView: ShieldView, context: Context) {
        // Update protection state if it changed
        uiView.setProtected(isProtected)
        
        // Update the hosted SwiftUI content
        context.coordinator.hostingController?.rootView = content
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    /// Coordinator that holds a reference to the hosting controller.
    public class Coordinator {
        /// The hosting controller for the SwiftUI content.
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
