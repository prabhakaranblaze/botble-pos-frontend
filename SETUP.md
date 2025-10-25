# Quick Setup Guide

## Prerequisites
1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
2. Install Visual Studio 2022 with C++ workload

## Steps

### 1. Configure API
Edit `lib/shared/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://localhost/api/v1/pos'; // Your API URL
static const String apiKey = 'YOUR_API_KEY_HERE'; // Your API key
```

### 2. Install Dependencies
```bash
cd pos_desktop
flutter pub get
```

### 3. Enable Windows Desktop
```bash
flutter config --enable-windows-desktop
```
```bash
flutter create --platforms=windows .
```
### 4. Run
```bash
flutter run -d windows
```

## Default Login
- Email: admin@example.com
- Password: 12345678

## Need Help?
See README.md for detailed documentation.
