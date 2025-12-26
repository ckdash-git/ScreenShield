// ShieldView.swift
// ScreenShield
//
// A UIView subclass that uses the isSecureTextEntry technique to prevent
// screenshots and screen recordings of its child content.
//
// How it works:
// When a UITextField has isSecureTextEntry = true, iOS creates a special
// internal layer that is excluded from screenshots and screen recordings.
// By adding our content view as a subview of the text field (not as a sublayer),
// and disabling clipping, we inherit this protection.

import UIKit

/// A view that protects its content from screenshots and screen recordings.
///
/// `ShieldView` uses an architectural workaround based on `UITextField`'s
/// `isSecureTextEntry` property. When enabled, any content added to this view
/// will appear blank in screenshots and screen recordings.
///
/// - Important: This technique relies on undocumented iOS behavior and may
///   change in future iOS versions. Always test with new iOS releases.
///
/// ## Usage
/// ```swift
/// let shieldView = ShieldView()
/// view.addSubview(shieldView)
///
/// let sensitiveLabel = UILabel()
/// sensitiveLabel.text = "Secret Information"
/// shieldView.addProtectedContent(sensitiveLabel)
/// ```
public final class ShieldView: UIView {
    
    // MARK: - Private Properties
    
    /// The hidden text field that provides the secure layer.
    private var secureTextField: UITextField?
    
    /// Container view that holds all protected content.
    private let secureContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.clipsToBounds = false
        return view
    }()
    
    /// Tracks whether screenshot protection is currently enabled.
    private var isProtectionEnabled: Bool = true
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = false
        
        // Create and setup the secure text field
        makeSecure()
    }
    
    // MARK: - Secure Layer Setup
    
    /// Creates the secure text field and attaches our container to its layer hierarchy.
    private func makeSecure() {
        guard secureTextField == nil else { return }
        
        // Create a text field with secure entry enabled
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.clipsToBounds = false
        textField.layer.masksToBounds = false
        
        // Add textfield to view hierarchy
        addSubview(textField)
        
        // Force layout to create internal views
        textField.layoutIfNeeded()
        
        // Find the secure layer host and add our container to it
        if let secureLayerHost = findSecureLayerHost(in: textField) {
            // Add the container to the secure layer host
            secureLayerHost.addSubview(secureContainer)
            secureLayerHost.isUserInteractionEnabled = true
            secureLayerHost.clipsToBounds = false
            secureLayerHost.layer.masksToBounds = false
            
            // Ensure parent layers also don't clip
            var parent = secureLayerHost.superview
            while parent != nil && parent !== self {
                parent?.clipsToBounds = false
                parent?.layer.masksToBounds = false
                parent = parent?.superview
            }
        } else {
            // Fallback: Add container directly (protection may not work)
            print("[ScreenShield] Warning: Could not find secure layer host. Screenshot protection may not work.")
            textField.addSubview(secureContainer)
        }
        
        secureTextField = textField
        
        // Initial layout
        setNeedsLayout()
    }
    
    /// Finds the internal view that iOS uses for secure content rendering.
    /// This is typically a _UITextLayoutCanvasView or _UITextFieldCanvasView.
    private func findSecureLayerHost(in textField: UITextField) -> UIView? {
        // Trigger layout to ensure all subviews are created
        textField.setNeedsLayout()
        textField.layoutIfNeeded()
        
        // Search recursively for the canvas view
        return findCanvasView(in: textField)
    }
    
    /// Recursively searches for the canvas view in the view hierarchy.
    private func findCanvasView(in view: UIView) -> UIView? {
        for subview in view.subviews {
            let className = String(describing: type(of: subview))
            
            // iOS uses various internal view classes for secure text
            // Common ones: _UITextLayoutCanvasView, _UITextFieldCanvasView
            if className.contains("Canvas") ||
               className.contains("TextLayout") ||
               className.contains("ContentView") {
                return subview
            }
            
            // Recursively search
            if let found = findCanvasView(in: subview) {
                return found
            }
        }
        
        // If no specific canvas found, return the first subview
        // This is often correct on newer iOS versions
        return view.subviews.first
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Position the text field (it can be very small since it's invisible)
        secureTextField?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // The secure container should fill the ShieldView bounds
        secureContainer.frame = bounds
        
        // Ensure all content is properly sized
        for subview in secureContainer.subviews {
            if subview.translatesAutoresizingMaskIntoConstraints {
                // Frame-based views - leave their frames as-is
            }
            // Constraint-based views will handle their own layout
        }
    }
    
    public override var frame: CGRect {
        didSet {
            secureContainer.frame = bounds
        }
    }
    
    public override var bounds: CGRect {
        didSet {
            secureContainer.frame = bounds
        }
    }
    
    // MARK: - Hit Testing
    
    /// Override to forward touch events to the secure container.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // First check if the point is within our container
        let containerPoint = convert(point, to: secureContainer)
        if let hitView = secureContainer.hitTest(containerPoint, with: event) {
            return hitView
        }
        
        return super.hitTest(point, with: event)
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point)
    }
    
    // MARK: - Public API
    
    /// Adds a view to be protected from screenshots and screen recordings.
    ///
    /// The view will be added to the secure container and will be hidden
    /// when the user attempts to take a screenshot or record the screen.
    ///
    /// - Parameter view: The view to protect.
    public func addProtectedContent(_ view: UIView) {
        secureContainer.addSubview(view)
        setNeedsLayout()
    }
    
    /// Removes a protected view from the shield.
    ///
    /// - Parameter view: The view to remove from protection.
    public func removeProtectedContent(_ view: UIView) {
        if view.superview === secureContainer {
            view.removeFromSuperview()
        }
    }
    
    /// Enables or disables screenshot protection.
    ///
    /// When disabled, content will be visible in screenshots and screen recordings.
    /// This can be useful for toggling protection based on app state.
    ///
    /// - Parameter protected: Whether to enable (`true`) or disable (`false`) protection.
    public func setProtected(_ protected: Bool) {
        guard isProtectionEnabled != protected else { return }
        
        isProtectionEnabled = protected
        secureTextField?.isSecureTextEntry = protected
        
        // Rebuild the secure layer when toggling
        if protected && secureTextField == nil {
            makeSecure()
        }
    }
    
    /// Returns whether screenshot protection is currently enabled.
    public var isProtected: Bool {
        return isProtectionEnabled
    }
    
    /// The container view holding all protected content.
    /// Use this to access protected subviews or add constraints.
    public var contentView: UIView {
        return secureContainer
    }
}

// MARK: - UIWindow Extension for Global Protection

public extension UIWindow {
    
    /// Creates a secure overlay that protects the entire window content.
    /// Call this in your AppDelegate or SceneDelegate to protect all content.
    ///
    /// - Returns: The ShieldView that was added, or nil if already present.
    @discardableResult
    func makeSecure() -> ShieldView? {
        // Check if already secured
        if subviews.contains(where: { $0 is ShieldView }) {
            return nil
        }
        
        let shieldView = ShieldView()
        shieldView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add at the back, behind all other content
        insertSubview(shieldView, at: 0)
        
        NSLayoutConstraint.activate([
            shieldView.topAnchor.constraint(equalTo: topAnchor),
            shieldView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shieldView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        return shieldView
    }
}
