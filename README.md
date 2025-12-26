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
- **Dynamic Control**: Toggle protection on or off dynamically (e.g., via server-side configuration).
- **Privacy Blur**: Optional utility to automatically blur views when screen recording is detected.
- **Modular Design**: Zero dependencies; install via Swift Package Manager.
- **SwiftUI & UIKit**: First-class support for both frameworks.

---

## Installation

### Swift Package Manager

Add ScreenShield to your project via Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/ckdash-git/ScreenShield.git`
3. Select **Up to Next Major Version** (e.g., `1.0.0`).

Or add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ckdash-git/ScreenShield.git", from: "1.0.0")
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

```swift
import UIKit
import ScreenShield

class SecureViewController: UIViewController {
    
    private let shield = ShieldView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the shield
        shield.frame = view.bounds
        view.addSubview(shield)

        // 2. Add sensitive content to the shield
        let secretLabel = UILabel()
        secretLabel.text = "Sensitive Data"
        
        // IMPORTANT: Add to shield, not view
        shield.addProtectedContent(secretLabel) 
    }
    
    // Example: Toggle protection programmatically
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
