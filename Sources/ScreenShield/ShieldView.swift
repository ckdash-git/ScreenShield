// ShieldView.swift
// ScreenShield
//
// A UIView subclass that uses the isSecureTextEntry technique to prevent
// screenshots and screen recordings of its child content.
//
// How it works:
// When a UITextField has isSecureTextEntry = true, iOS creates a special
// internal layer that hides its content from screenshots and screen recordings.
// By attaching our content view to that secure layer, we inherit this protection.

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
    /// Its isSecureTextEntry property creates the protection mechanism.
    private let secureTextField: UITextField = {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        // Make the text field invisible but keep it in the view hierarchy
        textField.alpha = 0.01 // Nearly invisible, but still renders its secure layer
        return textField
    }()
    
    /// Container view that will be attached to the secure layer.
    /// All protected content is added to this container.
    private let secureContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// Tracks whether screenshot protection is currently enabled.
    private var isProtectionEnabled: Bool = true
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecureLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureLayer()
    }
    
    // MARK: - Setup
    
    /// Sets up the secure text field and attaches our container to its secure layer.
    private func setupSecureLayer() {
        // Add the secure text field to the view hierarchy
        // This is required for the secure layer to be active
        addSubview(secureTextField)
        
        // Constrain the text field to fill this view
        // The text field needs to be present but we only care about its layer
        NSLayoutConstraint.activate([
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Critical: We must wait for the text field to be laid out before
        // we can access its secure layer. Using DispatchQueue.main.async
        // ensures the text field's layers are initialized.
        DispatchQueue.main.async { [weak self] in
            self?.attachContainerToSecureLayer()
        }
    }
    
    /// Attaches the secure container to the text field's internal secure layer.
    /// This is where the magic happens - content in this container will be
    /// hidden from screenshots and screen recordings.
    private func attachContainerToSecureLayer() {
        // The secure text field creates a special sublayer when isSecureTextEntry is true.
        // We find this layer and add our container's layer to it.
        guard let secureLayer = findSecureLayer(in: secureTextField) else {
            // Fallback: If we can't find the secure layer, just add normally
            // This means protection won't work, but the view will still function
            print("[ScreenShield] Warning: Could not find secure layer. Protection may not work.")
            addSubview(secureContainer)
            constrainSecureContainer(to: self)
            return
        }
        
        // Add the container view to the secure layer
        // The container's layer will inherit the screenshot protection
        secureLayer.addSublayer(secureContainer.layer)
        
        // We still need the container in the view hierarchy for proper layout
        // and user interaction, but we make it hidden from the normal view
        addSubview(secureContainer)
        constrainSecureContainer(to: self)
        
        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    /// Recursively searches for the secure layer within the text field's layer hierarchy.
    /// The secure layer is typically the first sublayer of the text field's layer.
    private func findSecureLayer(in textField: UITextField) -> CALayer? {
        // Trigger layout to ensure layers are created
        textField.layoutIfNeeded()
        
        // The secure layer is usually at layer.sublayers?[0]
        // This is an implementation detail of UIKit's secure text field
        return textField.layer.sublayers?.first
    }
    
    /// Constrains the secure container to fill its parent.
    private func constrainSecureContainer(to parent: UIView) {
        secureContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureContainer.topAnchor.constraint(equalTo: parent.topAnchor),
            secureContainer.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            secureContainer.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            secureContainer.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the secure container's frame matches the bounds
        secureContainer.frame = bounds
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
        isProtectionEnabled = protected
        secureTextField.isSecureTextEntry = protected
        
        // When protection is disabled, we need to re-add content to normal view hierarchy
        // When enabled, we need to re-attach to secure layer
        if protected {
            attachContainerToSecureLayer()
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
