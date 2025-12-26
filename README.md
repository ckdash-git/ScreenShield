# ScreenShield

A lightweight Swift package to protect sensitive content from screenshots and screen recordings in iOS applications.

## Overview

ScreenShield uses an architectural workaround based on `UITextField`'s `isSecureTextEntry` property to hide sensitive content from screenshots and screen recordings. When protection is enabled, the content appears blank (or blurred for screen recordings) in captured media.

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add ScreenShield to your project using Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/ckdash-git/ScreenShield.git
   ```
3. Select the version rule (e.g., "Up to Next Major Version")
4. Click **Add Package**

Or add it manually to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ckdash-git/ScreenShield.git", from: "1.0.0")
]
```

Then add `ScreenShield` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["ScreenShield"]
)
```

## Usage

### SwiftUI

The simplest way to protect content in SwiftUI is using the `.protectScreenshot()` modifier:

```swift
import ScreenShield

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Public Information")
            
            Text("Secret: ABC-123-XYZ")
                .protectScreenshot()
        }
    }
}
```

You can also conditionally enable protection:

```swift
Text("Sensitive Data")
    .protectScreenshot(when: userSettings.hideInScreenshots)
```

For wrapping multiple views, use `ScreenShieldView`:

```swift
ScreenShieldView {
    VStack {
        Image(systemName: "creditcard.fill")
        Text("Card Number: 4242-4242-4242-4242")
        Text("CVV: 123")
    }
}
```

### UIKit

Create a `ShieldView` and add your sensitive content to it:

```swift
import ScreenShield

class SecureViewController: UIViewController {
    
    private let shieldView = ShieldView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the shield view to your hierarchy
        view.addSubview(shieldView)
        shieldView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shieldView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add protected content
        let secretLabel = UILabel()
        secretLabel.text = "Secret Information"
        secretLabel.translatesAutoresizingMaskIntoConstraints = false
        
        shieldView.addProtectedContent(secretLabel)
        
        // Constrain the label within the shield's content view
        NSLayoutConstraint.activate([
            secretLabel.centerXAnchor.constraint(equalTo: shieldView.contentView.centerXAnchor),
            secretLabel.centerYAnchor.constraint(equalTo: shieldView.contentView.centerYAnchor)
        ])
    }
}
```

### Screen Recording Detection

As a backup protection mechanism, you can detect screen recording and apply a blur:

```swift
import ScreenShield

// Option 1: Use the convenience extension
view.enableRecordingBlur()

// Option 2: Handle manually with callbacks
ScreenRecordingObserver.shared.startObserving { isRecording in
    if isRecording {
        // Hide or blur sensitive content
        sensitiveView.isHidden = true
    } else {
        // Show sensitive content
        sensitiveView.isHidden = false
    }
}

// Don't forget to stop observing when done
deinit {
    ScreenRecordingObserver.shared.stopObserving()
}
```

## How It Works

### The Secure Field Technique

iOS does not provide a public API to disable screenshots. However, `UITextField` with `isSecureTextEntry = true` creates an internal layer that is automatically excluded from screenshots and screen recordings (this is how password fields remain secure).

ScreenShield exploits this behavior by:

1. Creating an invisible `UITextField` with `isSecureTextEntry = true`
2. Attaching your content to the text field's internal secure layer
3. The content inherits the screenshot protection from the secure layer

```
UIWindow
 +-- ShieldView
     +-- UITextField (isSecureTextEntry = true, invisible)
         +-- layer.sublayers[0] (secure layer)
             +-- Your Protected Content
```

### Screen Recording Detection

`UIScreen.capturedDidChangeNotification` fires when screen recording or AirPlay mirroring starts/stops. ScreenShield uses this to optionally apply a blur effect during recording as an additional layer of protection.

## Important Disclaimer

> **Warning**: This package relies on undocumented iOS behavior. While the `isSecureTextEntry` technique has been used successfully in production apps and is unlikely to break (as it would affect password field security), Apple could theoretically change this behavior in future iOS versions.

**Recommendations:**

- Always test with new iOS releases
- Use screen recording detection as a backup
- Consider this one layer of a defense-in-depth security strategy
- Do not rely solely on this for highly sensitive data

## File Structure

```
ScreenShield/
+-- Package.swift
+-- README.md
+-- Sources/
    +-- ScreenShield/
        +-- ScreenShield.swift          # Public exports and documentation
        +-- ShieldView.swift            # Core UIKit implementation
        +-- ScreenRecordingObserver.swift # Recording detection
        +-- ScreenShieldView.swift      # SwiftUI wrapper
        +-- ScreenShieldModifier.swift  # ViewModifier
```

## API Reference

### ShieldView (UIKit)

| Method | Description |
|--------|-------------|
| `addProtectedContent(_ view: UIView)` | Adds a view to be protected |
| `removeProtectedContent(_ view: UIView)` | Removes a protected view |
| `setProtected(_ protected: Bool)` | Enables/disables protection |
| `isProtected: Bool` | Whether protection is currently enabled |
| `contentView: UIView` | Access to the container for layout constraints |

### ScreenShieldView (SwiftUI)

| Parameter | Description |
|-----------|-------------|
| `isProtected: Bool` | Whether protection is enabled (default: `true`) |
| `content: () -> Content` | The content to protect |

### View Extensions (SwiftUI)

| Modifier | Description |
|----------|-------------|
| `.protectScreenshot()` | Applies screenshot protection |
| `.protectScreenshot(when: Bool)` | Conditionally applies protection |

### ScreenRecordingObserver

| Method | Description |
|--------|-------------|
| `startObserving(handler:)` | Starts observing recording state |
| `stopObserving()` | Stops observing |
| `isScreenBeingCaptured: Bool` | Current recording state |

### UIView Extension

| Method | Description |
|--------|-------------|
| `enableRecordingBlur(using:style:)` | Automatically blurs when recording |

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

This technique is based on the widely-known `isSecureTextEntry` workaround used by various banking and security-focused iOS applications.
