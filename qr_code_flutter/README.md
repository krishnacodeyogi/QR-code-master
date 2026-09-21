# QR Studio - Mobile App (Flutter)

A premium Flutter mobile application for generating custom QR Codes, matching the design aesthetics and capabilities of the Web QR Studio application.

## Features

- **Dark Nebula Theme**: Sleek, glassmorphic layout using deep indigo/violet colors, glowing borders, and rounded components.
- **Real-Time Generation**: As you type, the QR code updates instantly.
- **Embedded Logos**: Pick any image from your gallery and embed it seamlessly in the center of the QR code (this automatically locks error correction to high-density level H).
- **Custom Color Palettes**: Choose from preset pairings (Nebula, Classic, Mint, Cyber Pink, Sunburst, Solar Gold) or define custom RGB colors via built-in sliders.
- **Size Adjustment**: Real-time slider to change the export dimensions (150px to 400px).
- **Error Correction Levels**: Manually choose L, M, Q, or H correction quality.
- **Scan Quality Indicator**: Informative check showing if your QR code is Excellent, Good, or too Dense to scan easily.
- **Easy Sharing**: Tap the "Share / Save QR Code" button to share the high-resolution PNG image directly using the native share menu (enabling instant saving to gallery, email, WhatsApp, etc.).

## Setup & Run

### Prerequisites
Make sure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.

1. Navigate to this directory:
   ```bash
   cd qr_code_flutter
   ```
2. Install packages:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected emulator or physical device:
   ```bash
   flutter run
   ```

## How to Build the APK (Android)

To compile a production-ready Release APK:

1. Run the build command:
   ```bash
   flutter build apk --release
   ```
2. The generated APK will be available at:
   `build/app/outputs/flutter-apk/app-release.apk`
