# 🔍 Google ML Kit Barcode Scanner - Flutter

A comprehensive Flutter application that showcases **all features** of Google ML Kit Barcode Scanning API (`google_mlkit_barcode_scanning: ^0.14.1`). This app demonstrates advanced barcode scanning capabilities with a beautiful, modern UI.

## ✨ Features Implemented

### 🎯 Core Barcode Scanning Features
- **Real-time scanning** with camera integration
- **All barcode formats** supported by Google ML Kit:
  - QR Code
  - Aztec
  - Data Matrix  
  - PDF417
  - Code 128
  - Code 39
  - Code 93
  - Codabar
  - EAN-13
  - EAN-8
  - ITF (Interleaved 2 of 5)
  - UPC-A
  - UPC-E

### 📊 Advanced Barcode Analysis
- **Barcode type detection** and classification
- **Corner point extraction** for precise positioning
- **Bounding box information** for barcode location
- **Detailed metadata extraction** for structured data

### 🔍 Specialized Barcode Content Parsing

#### 📧 Email Barcodes
- Email address extraction
- Subject line parsing
- Message body content
- Email type classification (Home/Work)

#### 📱 Contact Information (vCard)
- Full name parsing (First, Last, Formatted)
- Multiple phone numbers with type classification
- Multiple email addresses with type classification
- Organization and job title
- Complete contact card parsing

#### 📶 WiFi QR Codes
- SSID (Network name)
- Password extraction
- Encryption type detection (Open/WPA/WEP)
- Complete WiFi connection details

#### 📅 Calendar Events
- Event title and description
- Location information
- Organizer details
- Event status tracking
- Complete calendar integration data

#### 📞 Phone & SMS
- Phone number extraction
- Phone type classification (Home/Work/Mobile/Fax)
- SMS message content
- Recipient phone number for SMS

#### 🔗 URL & Web Links
- URL extraction and validation
- Page title parsing
- Complete web link information

### 🎨 User Interface Features
- **Modern Material Design 3** interface
- **Smooth animations** throughout the app
- **Custom scanner overlay** with corner detection
- **Real-time scanning line animation**
- **Beautiful gradient backgrounds**
- **Haptic feedback** on successful scans
- **Flash/torch control** for low-light scanning

### 🔧 Technical Features
- **High-performance camera integration**
- **Frame rate optimization** (processes every 3rd frame)
- **Cross-platform support** (Android & iOS)
- **Proper image format handling** (NV21/BGRA8888)
- **Memory-efficient image processing**
- **Automatic camera permission handling**
- **Error handling and user guidance**

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Physical device for testing (camera required)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/google_mlkit_barcode_scanning.git
cd google_mlkit_barcode_scanning
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run on device:**
```bash
flutter run
```

## 📦 Dependencies

The app uses the following key dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
    
  # Google ML Kit Barcode Scanning - Core functionality
  google_mlkit_barcode_scanning: ^0.14.1
  
  # Additional ML Kit features
  google_mlkit_face_detection: ^0.13.1
  google_mlkit_face_mesh_detection: ^0.4.1
  google_mlkit_text_recognition: ^0.15.0
  
  # Camera and permissions
  camera: ^0.11.0+2
  permission_handler: ^12.0.1
  
  # UI enhancements
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  animations: ^2.0.11
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── screens/
│   ├── home_screen.dart           # Main navigation screen
│   ├── barcode_scanner_screen.dart # Core scanning functionality
│   ├── result_screen.dart         # Detailed results display
│   ├── face_detection_screen.dart # Face detection features
│   ├── face_mesh_detection_screen.dart # Face mesh features
│   └── text_recognition_screen.dart # Text recognition features
```

## 🔍 Core Implementation Details

### Barcode Scanner Configuration

```dart
// All supported barcode formats
List<BarcodeFormat> _selectedFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.aztec,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.pdf417,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.itf,
  BarcodeFormat.upca,
  BarcodeFormat.upce,
];

// Initialize scanner with all formats
_barcodeScanner = BarcodeScanner(formats: _selectedFormats);
```

### Advanced Barcode Analysis

```dart
// Extract all available barcode information
final barcodes = await _barcodeScanner.processImage(inputImage);
for (final barcode in barcodes) {
  // Basic information
  final format = barcode.format;
  final type = barcode.type;
  final value = barcode.rawValue ?? barcode.displayValue;
  
  // Geometric information
  final boundingBox = barcode.boundingBox;
  final cornerPoints = barcode.cornerPoints;
  
  // Structured data parsing
  switch (barcode.type) {
    case BarcodeType.wifi:
      final wifi = barcode.wifi;
      final ssid = wifi?.ssid;
      final password = wifi?.password;
      final encryption = wifi?.encryptionType;
      break;
      
    case BarcodeType.contactInfo:
      final contact = barcode.contactInfo;
      final name = contact?.name?.formattedName;
      final phones = contact?.phones;
      final emails = contact?.emails;
      break;
      
    // ... handle all other types
  }
}
```

## 📱 Supported Barcode Types

### Standard Barcodes
- **QR Code**: Most versatile, supports all data types
- **Data Matrix**: Compact 2D barcode
- **PDF417**: High-capacity 2D barcode
- **Aztec**: Compact, reliable 2D format

### Linear Barcodes
- **Code 128**: Variable-length, high-density
- **Code 39**: Alphanumeric encoding
- **Code 93**: Enhanced version of Code 39
- **Codabar**: Numeric with special characters
- **EAN-13/8**: European retail standard
- **UPC-A/E**: Universal Product Code
- **ITF**: Interleaved 2 of 5

### Structured Data Types
- **Contact Info** (vCard format)
- **WiFi** (Network configuration)
- **Email** (mailto: links)
- **Phone** (tel: links)
- **SMS** (sms: links)
- **URL** (Web links)
- **Calendar Events** (vEvent format)

## ⚡ Performance Optimization

The app implements several performance optimizations:

1. **Frame Rate Control**: Processes every 3rd camera frame
2. **Memory Management**: Efficient image byte handling
3. **Background Processing**: Non-blocking barcode analysis
4. **Resource Cleanup**: Proper disposal of cameras and scanners

## 🔒 Permissions

The app requires camera permission for barcode scanning:

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan barcodes and QR codes.</string>
```

## 🎯 Use Cases

This comprehensive barcode scanner can be used for:

- **Retail & Inventory**: Product scanning and management
- **Event Management**: Ticket scanning and validation
- **Contact Sharing**: Quick vCard exchange
- **WiFi Sharing**: Instant network connection
- **Payment Systems**: QR code payments
- **Document Management**: PDF417 document codes
- **Library Systems**: ISBN book scanning
- **Marketing**: QR code campaigns

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google ML Kit Team** for the excellent barcode scanning API
- **Flutter Team** for the amazing framework
- **Camera Plugin Contributors** for camera integration
- **Community** for testing and feedback

## 📞 Support

If you have any questions or need help with implementation, please:

1. Check the [Issues](https://github.com/yourusername/google_mlkit_barcode_scanning/issues) page
2. Create a new issue with detailed information
3. Review the Google ML Kit documentation

---

**Built with ❤️ using Flutter & Google ML Kit**

*This app demonstrates the complete capabilities of Google ML Kit Barcode Scanning API with a focus on user experience and performance.*
#   - _ b a r c o d e S c a n n e r - B a r c o d e S c a n n e r - f o r m a t s - _ s e l e c t e d F o r m a t s -  
 