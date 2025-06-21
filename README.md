# QR Code Studio 🎨

A stunning, modern iOS app for generating beautiful QR codes with a focus on exceptional design and user experience. Built with SwiftUI and featuring glassmorphism UI, smooth animations, and multiple QR code styles.

![QR Code Studio Banner](https://via.placeholder.com/1200x600/6B46C1/FFFFFF?text=QR+Code+Studio)

## ✨ Features

### 🎯 Core Functionality
- **Instant QR Generation** - Real-time QR code creation from any URL
- **Multiple Styles** - Choose from Minimal, Branded, Gradient, or Glass effects
- **Brand Customization** - Add your company logo and custom colors
- **Save & Share** - Export QR codes directly to Photos or share via iOS Share Sheet
- **Toast Notifications** - Beautiful feedback system for user actions

### 🎨 Design Features
- **Glassmorphism UI** - Modern translucent design elements
- **Animated Backgrounds** - Floating glass orbs with subtle movements
- **Spring Animations** - Smooth, natural transitions throughout
- **Gradient Effects** - Eye-catching purple-blue gradients
- **Haptic Feedback** - Tactile responses for better UX

## 📱 Screenshots

<table>
  <tr>
    <td><img src="https://via.placeholder.com/300x650/F3F4F6/6B46C1?text=Main+Screen" alt="Main Screen" width="250"/></td>
    <td><img src="https://via.placeholder.com/300x650/F3F4F6/6B46C1?text=Style+Selection" alt="Style Selection" width="250"/></td>
    <td><img src="https://via.placeholder.com/300x650/F3F4F6/6B46C1?text=Generated+QR" alt="Generated QR" width="250"/></td>
  </tr>
</table>

## 🚀 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 📦 Installation

### Option 1: Clone the Repository

```bash
git clone https://github.com/yourusername/qr-code-studio.git
cd qr-code-studio
open QRCodeStudio.xcodeproj
```

### Option 2: Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/qr-code-studio.git", from: "1.0.0")
]
```

## 🛠 Setup

1. **Add Required Permissions**
   
   Add the following to your `Info.plist`:
   ```xml
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>QR Code Studio needs access to save QR codes to your photo library</string>
   
   <key>NSPhotoLibraryUsageDescription</key>
   <string>QR Code Studio needs access to select logos from your photo library</string>
   ```

2. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## 💻 Usage

### Basic QR Code Generation

```swift
// Simply enter a URL in the text field
// Select a style from the style picker
// Tap "Generate QR Code"
```

### Customization Options

1. **Minimal Style** - Classic black and white QR code
2. **Branded Style** - Add custom colors and company logo
3. **Gradient Style** - Beautiful purple-blue gradient effect
4. **Glass Style** - Semi-transparent, ethereal appearance

### Code Integration

```swift
// Generate a basic QR code
let generator = QRCodeGenerator()
let qrImage = generator.generateBasicQR(from: "https://example.com")

// Generate a custom colored QR
let customQR = generator.generateCustomQR(
    from: "https://example.com",
    foreground: .purple,
    background: .white,
    logo: logoImage
)
```

## 🏗 Architecture

```
QRCodeStudio/
├── Views/
│   ├── ContentView.swift       # Main app interface
│   ├── ToastView.swift        # Toast notification component
│   ├── StyleCard.swift        # Style selection cards
│   └── ActionButton.swift     # Reusable button component
├── Models/
│   ├── QRStyle.swift          # QR code style definitions
│   └── ToastType.swift        # Toast notification types
├── Services/
│   └── QRCodeGenerator.swift  # Core QR generation logic
└── Helpers/
    ├── ImagePicker.swift      # Photo library integration
    └── ShareSheet.swift       # iOS share functionality
```

## 🎨 Customization

### Colors
Modify the gradient colors in `ContentView.swift`:
```swift
LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.95, green: 0.95, blue: 1.0),
        Color(red: 0.85, green: 0.9, blue: 1.0),
        Color(red: 0.9, green: 0.85, blue: 1.0)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Animation Timing
Adjust animation durations:
```swift
.animation(
    Animation.easeInOut(duration: 2.0)  // Modify duration
        .repeatForever(autoreverses: true),
    value: animateQR
)
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure all UI elements support Dynamic Type
- Test on multiple device sizes

## 📋 Roadmap

- [ ] Dark mode support
- [ ] QR code scanning functionality
- [ ] Batch QR generation
- [ ] Custom frames and templates
- [ ] Export in multiple sizes
- [ ] iCloud sync for saved QR codes
- [ ] Widget support for quick access
- [ ] macOS Catalyst support

## 🐛 Known Issues

- Logo sizing may need adjustment for very small logos
- Gradient QR codes may not scan well in low light conditions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and love ❤️
- Inspired by modern iOS design trends
- Uses Core Image for QR generation
- Special thanks to the iOS development community

## 📧 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/qr-code-studio](https://github.com/yourusername/qr-code-studio)

---

<p align="center">
  Made with ❤️ by [Your Name]
</p>

<p align="center">
  <a href="https://github.com/yourusername/qr-code-studio/stargazers">
    <img src="https://img.shields.io/github/stars/yourusername/qr-code-studio?style=social" alt="Stars">
  </a>
  <a href="https://github.com/yourusername/qr-code-studio/network/members">
    <img src="https://img.shields.io/github/forks/yourusername/qr-code-studio?style=social" alt="Forks">
  </a>
</p>
