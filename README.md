# ScreenShield

![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)
![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

**The missing privacy layer for iOS applications.**

ScreenShield is a production-ready Swift Package that prevents sensitive content from being captured in screenshots or screen recordings. It provides a modular, drop-in solution for both **SwiftUI** and **UIKit**, eliminating the need to rewrite complex security logic for every project.

---

## Features

- **Screenshot Prevention**: Content rendered inside ScreenShield becomes invisible (black/white) in system screenshots.
- **Recording Protection**: Content is automatically hidden during screen recording or AirPlay mirroring.
- **App Switcher Privacy** *(New in 1.3.0)*: Blur overlay when app enters background to protect App Switcher snapshots.
- **Screenshot Notifications** *(New in 1.3.0)*: Callback when user takes a screenshot for logging or alerts.
- **Placeholder Content** *(New in 1.3.0)*: Show custom "Content Protected" view in screenshots instead of blank space.
- **External Display Detection** *(New in 1.3.0)*: Differentiate between screen recording and AirPlay/external displays.
- **Dynamic Control**: Toggle protection on or off dynamically (e.g., via server-side configuration).
- **Privacy Blur**: Optional utility to automatically blur views when screen recording is detected.
- **Accessibility Support** *(Enhanced in 1.3.0)*: VoiceOver-friendly implementation.
- **Modular Design**: Zero dependencies; install via Swift Package Manager.
- **SwiftUI & UIKit**: First-class support for both frameworks.

---

## Installation

### Swift Package Manager

Add ScreenShield to your project via Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/ckdash-git/ScreenShield.git`
3. Select **Up to Next Major Version** (e.g., `1.3.0`).

Or add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ckdash-git/ScreenShield.git", from: "1.3.0")
]
```

---

## Usage

### SwiftUI

The easiest way to protect content is using the `.protectScreenshot()` view modifier.

```swift
import SwiftUI
import ScreenShield

struct SecureView: View {
    var body: some View {
        VStack {
            // This is visible in screenshots
            Text("Public Header")

            // This is HIDDEN in screenshots
            Text("Your Secret API Key: 12345")
                .protectScreenshot()
        }
    }
}
```

### Dynamic & Server-Controlled Protection

You can enable or disable protection dynamically based on your app's state or a remote configuration (e.g., a server response). This is useful if you want to control security features via a backend flag.

ScreenShield supports initialization with a boolean state:

```swift
public init(isProtected: Bool = true)
```

**Usage Example:**

```swift
// Example: Toggling protection based on a server response
struct UserProfileView: View {
    // This boolean could come from your backend API
    let serverConfigAllowScreenshots: Bool 
    
    var body: some View {
        VStack {
            Text("Sensitive User Data")
                // Pass the server response state to control protection
                // If the server says "allow", we pass false (enabled = false)
                .protectScreenshot(!serverConfigAllowScreenshots)
        }
    }
}
```

Or using the `ScreenShieldView` wrapper explicitly:

```swift
ScreenShieldView(isProtected: viewModel.isSecurityEnabled) {
    SensitiveChart()
}
```

---

### UIKit

Wrap your sensitive views inside a `ShieldView`.

#### Basic Usage (Frame-based)

```swift
import UIKit
import ScreenShield

class SecureViewController: UIViewController {
    
    private let shield = ShieldView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Add the shield to your view
        shield.frame = view.bounds
        shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(shield)

        // 2. Add sensitive content to the shield
        let secretLabel = UILabel()
        secretLabel.text = "Sensitive Data"
        secretLabel.frame = CGRect(x: 20, y: 100, width: 200, height: 44)
        
        // IMPORTANT: Add to shield's contentView, not directly to view
        shield.addProtectedContent(secretLabel) 
    }
}
```

#### Auto Layout Usage

```swift
import UIKit
import ScreenShield

class SecureViewController: UIViewController {
    
    private let shield = ShieldView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Setup shield with Auto Layout
        shield.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shield)
        
        NSLayoutConstraint.activate([
            shield.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            shield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 2. Add content with constraints
        let secretLabel = UILabel()
        secretLabel.text = "Protected Credit Card: 4242-4242-4242-4242"
        secretLabel.translatesAutoresizingMaskIntoConstraints = false
        
        shield.addProtectedContent(secretLabel)
        
        // Constrain relative to shield's contentView
        NSLayoutConstraint.activate([
            secretLabel.centerXAnchor.constraint(equalTo: shield.contentView.centerXAnchor),
            secretLabel.centerYAnchor.constraint(equalTo: shield.contentView.centerYAnchor)
        ])
    }
}
```

#### Dynamic & Server-Controlled Protection (UIKit)

Toggle protection programmatically based on server configuration:

```swift
class SecureViewController: UIViewController {
    
    private let shield = ShieldView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupShield()
        
        // Fetch server configuration
        fetchServerConfig()
    }
    
    private func fetchServerConfig() {
        APIService.getSecurityConfig { [weak self] config in
            DispatchQueue.main.async {
                // Enable/disable based on server response
                self?.shield.setProtected(config.screenshotProtectionEnabled)
            }
        }
    }
    
    // Public method to toggle protection
    func updateSecurityState(enabled: Bool) {
        shield.setProtected(enabled)
    }
}
```

---

### Screen Recording Blur (Backup Layer)

While the core protection hides content, you may also want to blur the entire view when a user starts recording the screen or mirroring to a TV.

```swift
// Automatically blurs the view when recording starts
myView.enableRecordingBlur(style: .dark)
```

---

### Global Window Protection

For apps that need to secure the entire window hierarchy efficiently:

```swift
// In your SceneDelegate or AppDelegate
window?.makeSecure()
```

---

## New in Version 1.3.0

### App Switcher Privacy (Background Blur)

Protect your app's content from appearing in the iOS App Switcher:

```swift
// SwiftUI - Add to your root view
ContentView()
    .enableBackgroundPrivacy(style: .regular)

// UIKit - In AppDelegate or SceneDelegate
ScreenShieldManager.shared.enableBackgroundPrivacy(style: .dark)
```

### Screenshot Attempt Notifications

Get notified when users take screenshots:

```swift
// SwiftUI
ContentView()
    .onScreenshotAttempt {
        showSecurityWarning = true
    }

// UIKit
shieldView.onScreenshotAttempt = {
    print("Screenshot detected!")
}

// Global (App-wide)
ScreenShieldManager.shared.onScreenshotAttempt = {
    Analytics.log("screenshot_attempt")
}
```

### Placeholder Content

Show custom content in screenshots instead of blank space:

```swift
let placeholder = UILabel()
placeholder.text = "🔒 Content Protected"
placeholder.textAlignment = .center

shieldView.placeholderView = placeholder
```

### Enhanced External Display Detection

Differentiate between screen recording and AirPlay mirroring:

```swift
// Check current state
ScreenRecordingObserver.shared.hasExternalDisplay      // AirPlay/CarPlay connected?
ScreenRecordingObserver.shared.isRecordingOnly         // Recording without external display?
ScreenRecordingObserver.shared.isMirroringToExternalDisplay  // Mirroring to external?

// Observe with separate callbacks
ScreenRecordingObserver.shared.startObservingWithDetail(
    onRecordingStarted: { print("Recording started") },
    onRecordingStopped: { print("Recording stopped") },
    onExternalDisplayConnected: { print("AirPlay connected") },
    onExternalDisplayDisconnected: { print("AirPlay disconnected") }
)
```

---

## Simulator vs. Device

> **Important**: Screenshot protection does **not** work on the iOS Simulator.

The architectural workaround relies on the device's hardware graphics pipeline, which handles secure layers differently than the Simulator's software renderer.

| Environment | Behavior |
|-------------|----------|
| **Simulator** | Content will likely remain visible in screenshots |
| **Real Device** | Content will be hidden/blacked out |

**Always test your implementation on a physical iPhone or iPad.**

---

## How It Works

ScreenShield leverages a specialized architectural behavior in iOS. When a `UITextField` is set to `isSecureTextEntry = true`, the system creates a secure rendering layer to hide password characters from the OS's screenshot buffer.

ScreenShield injects your custom views into this secure layer hierarchy, effectively tricking the OS into treating your entire UI as a "password field." This renders it visible to the user but invisible to the screenshot engine.

```
UIWindow
 +-- ShieldView
     +-- UITextField (isSecureTextEntry = true)
         +-- Internal Secure Layer
             +-- Your Protected Content (invisible to screenshots)
```

---

## API Reference

### SwiftUI Modifiers

| Modifier | Description |
|----------|-------------|
| `.protectScreenshot()` | Enables protection with default settings. |
| `.protectScreenshot(_ enabled: Bool)` | Toggles protection based on the boolean. |
| `.protectScreenshot(when: Bool)` | Alias for the above, for better readability. |

### ShieldView (UIKit)

| Method | Description |
|--------|-------------|
| `addProtectedContent(_:)` | Adds a subview to the secure container. |
| `removeProtectedContent(_:)` | Removes a subview from the secure container. |
| `setProtected(_:)` | Toggles the secure state. |
| `isProtected` | Returns the current state. |
| `contentView` | Access the container for Auto Layout constraints. |

### Utilities

| Method | Description |
|--------|-------------|
| `UIView.enableRecordingBlur()` | Adds an automatic blur effect during screen capture. |
| `UIWindow.makeSecure()` | Secures the entire window hierarchy. |
| `ScreenRecordingObserver.shared` | Singleton to listen for recording start/stop events manually. |

### ScreenShieldManager (New in 1.3.0)

| Method/Property | Description |
|-----------------|-------------|
| `enableBackgroundPrivacy(style:)` | Enables blur when app enters background. |
| `disableBackgroundPrivacy()` | Disables background blur. |
| `onScreenshotAttempt` | Closure called when screenshot is taken. |
| `isBackgroundPrivacyActive` | Returns whether background privacy is enabled. |

### ScreenRecordingObserver (Enhanced in 1.3.0)

| Method/Property | Description |
|-----------------|-------------|
| `startObservingWithDetail(...)` | Separate callbacks for recording vs external display. |
| `hasExternalDisplay` | Whether an external display is connected. |
| `isRecordingOnly` | Whether recording without external display. |
| `isMirroringToExternalDisplay` | Whether mirroring to external display. |

---

## Example App

The repository includes a demo app in the `Example/` folder that showcases all ScreenShield features:

- **Protection Toggle**: Enable/disable protection in real-time
- **Comparison View**: Side-by-side protected vs unprotected content
- **Credit Card Demo**: Realistic sensitive data protection example

### Running the Example

1. Open `Example/ScreenShieldDemo.xcodeproj` in Xcode
2. Select an iOS Simulator or physical device
3. Build and Run (Cmd + R)
4. Take a screenshot to see protection in action

---

## Disclaimer

> **Warning**: This package relies on `isSecureTextEntry` behavior.

While this approach is widely used in banking and enterprise apps and has been stable for years, it relies on the underlying behavior of iOS's text rendering engine. Apple does not provide a public "Block Screenshot" API.

**Use this as part of a defense-in-depth security strategy.**

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## License

ScreenShield is released under the **MIT License**. See [LICENSE](LICENSE) for details.
