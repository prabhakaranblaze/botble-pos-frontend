# Android Kiosk POS - Architecture Document

## Overview

This document outlines the architecture for adapting the StampSmart POS Flutter application to support Android kiosk devices with dual displays.

## Target Hardware

**Android Kiosk Device Specifications:**
- **OS:** Secure Android 11
- **CPU:** ARM Cortex A-55 64-bit 2.0GHz
- **RAM:** 2GB / 4GB (optional)
- **Storage:** 16GB / 32GB Flash
- **Main Display:** 15.6" FHD (1920x1080) capacitive touch
- **Customer Display:** 10.1" (1280x800) capacitive touch (optional)
- **Printer:** 80mm thermal (built-in, optional)
- **Connectivity:** Wi-Fi 2.4G/5.0, BT 5.4, Ethernet 100M, USB 2.0 x4

---

## Architecture

### Single Codebase Strategy

```
pos_desktop/
├── lib/
│   ├── core/
│   │   ├── platform/                    # NEW: Platform abstraction
│   │   │   ├── platform_interface.dart  # Abstract interface
│   │   │   ├── platform_windows.dart    # Windows implementation
│   │   │   └── platform_android.dart    # Android implementation
│   │   ├── database/
│   │   │   └── database_service.dart    # Conditional sqflite import
│   │   ├── services/
│   │   │   ├── update_service.dart      # Platform-specific updates
│   │   │   └── printer_service.dart     # Extended for built-in printer
│   │   └── ...
│   ├── features/
│   │   ├── customer_display/            # NEW: Customer-facing screen
│   │   │   ├── customer_display_screen.dart
│   │   │   ├── customer_display_provider.dart
│   │   │   └── widgets/
│   │   │       ├── cart_summary_widget.dart
│   │   │       ├── promotion_carousel.dart
│   │   │       └── idle_screen.dart
│   │   └── ...
├── android/                             # Android-specific config
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # Kiosk mode config
│   │   └── kotlin/.../
│   │       └── MainActivity.kt          # Dual display handling
├── windows/                             # Windows-specific config
└── pubspec.yaml                         # Conditional dependencies
```

---

## Platform Abstraction Layer

### Interface Definition

```dart
// lib/core/platform/platform_interface.dart

abstract class PlatformService {
  /// Platform identification
  bool get isWindows;
  bool get isAndroid;

  /// Window/Display management
  Future<void> setFullScreen(bool fullscreen);
  Future<bool> isFullScreen();

  /// Update mechanism
  Future<void> installUpdate(String installerPath);
  String get updateFileExtension; // '.exe' or '.apk'

  /// Customer display (Android only)
  bool get supportsCustomerDisplay;
  Future<void> showCustomerDisplay(Widget content);
  Future<void> hideCustomerDisplay();

  /// Built-in printer (Android kiosk only)
  bool get hasBuiltInPrinter;
  Future<void> printToBuiltIn(List<int> data);
}
```

### Windows Implementation

```dart
// lib/core/platform/platform_windows.dart

class PlatformWindows implements PlatformService {
  @override
  bool get isWindows => true;
  bool get isAndroid => false;

  @override
  Future<void> setFullScreen(bool fullscreen) async {
    await windowManager.setFullScreen(fullscreen);
  }

  @override
  Future<void> installUpdate(String path) async {
    await Process.start(path, ['/SILENT', '/CLOSEAPPLICATIONS'],
      mode: ProcessStartMode.detached);
    exit(0);
  }

  @override
  String get updateFileExtension => '.exe';

  @override
  bool get supportsCustomerDisplay => false;

  @override
  bool get hasBuiltInPrinter => false;
}
```

### Android Implementation

```dart
// lib/core/platform/platform_android.dart

class PlatformAndroid implements PlatformService {
  @override
  bool get isWindows => false;
  bool get isAndroid => true;

  @override
  Future<void> setFullScreen(bool fullscreen) async {
    // Android uses immersive mode via system UI
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge
    );
  }

  @override
  Future<void> installUpdate(String path) async {
    // Use android_package_installer or install intent
    await OpenFile.open(path);
  }

  @override
  String get updateFileExtension => '.apk';

  @override
  bool get supportsCustomerDisplay => true;

  @override
  bool get hasBuiltInPrinter => true; // Configurable
}
```

---

## Customer Display System

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MAIN APP                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   SalesProvider                          │    │
│  │  - cart items                                            │    │
│  │  - totals                                                │    │
│  │  - current order                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│                              │ notifyListeners()                 │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              CustomerDisplayProvider                     │    │
│  │  - mirrors cart state                                    │    │
│  │  - manages idle state                                    │    │
│  │  - handles promotions                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
└──────────────────────────────│───────────────────────────────────┘
                               │
                               │ Android Presentation API
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMER DISPLAY (10.1")                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │   ┌─────────────────────────────────────────────┐       │    │
│  │   │           LOGO / BRANDING                    │       │    │
│  │   └─────────────────────────────────────────────┘       │    │
│  │                                                          │    │
│  │   STATE: IDLE          │   STATE: ACTIVE                │    │
│  │   ┌─────────────────┐  │   ┌─────────────────────┐     │    │
│  │   │  Promotion      │  │   │  Your Order          │     │    │
│  │   │  Carousel       │  │   │  ────────────────    │     │    │
│  │   │                 │  │   │  Coffee x2   $10.00  │     │    │
│  │   │  [Auto-rotate]  │  │   │  Bread x1    $5.00   │     │    │
│  │   │                 │  │   │  ────────────────    │     │    │
│  │   └─────────────────┘  │   │  TOTAL:      $15.00  │     │    │
│  │                        │   └─────────────────────┘     │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Customer Display States

| State | Trigger | Content |
|-------|---------|---------|
| **Idle** | Cart empty for 30s | Logo + Promotion carousel |
| **Active** | Items in cart | Cart items + running total |
| **Checkout** | Payment initiated | Final total + "Processing..." |
| **Complete** | Payment success | "Thank you!" + Receipt summary |

### Customer Display Provider

```dart
// lib/features/customer_display/customer_display_provider.dart

class CustomerDisplayProvider with ChangeNotifier {
  final SalesProvider _salesProvider;

  CustomerDisplayState _state = CustomerDisplayState.idle;
  Timer? _idleTimer;
  int _currentPromoIndex = 0;

  // Promotions loaded from backend or local config
  List<Promotion> promotions = [];

  CustomerDisplayProvider(this._salesProvider) {
    _salesProvider.addListener(_onCartChanged);
    _startIdleTimer();
  }

  void _onCartChanged() {
    if (_salesProvider.cart.items.isNotEmpty) {
      _state = CustomerDisplayState.active;
      _resetIdleTimer();
    }
    notifyListeners();
  }

  void _startIdleTimer() {
    _idleTimer = Timer(Duration(seconds: 30), () {
      if (_salesProvider.cart.items.isEmpty) {
        _state = CustomerDisplayState.idle;
        notifyListeners();
      }
    });
  }

  // Cart data for display
  List<CartItem> get cartItems => _salesProvider.cart.items;
  double get subtotal => _salesProvider.cart.subtotal;
  double get total => _salesProvider.cart.total;
  double get discount => _salesProvider.discountAmount;
}
```

---

## Database Abstraction

### Conditional Import Strategy

```dart
// lib/core/database/database_service.dart

import 'database_stub.dart'
    if (dart.library.ffi) 'database_ffi.dart'      // Windows
    if (dart.library.html) 'database_web.dart'     // Web (future)
    as database_impl;

class DatabaseService {
  Future<Database> get database => database_impl.getDatabase();
}
```

```dart
// lib/core/database/database_ffi.dart (Windows)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> getDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return openDatabase(...);
}
```

```dart
// lib/core/database/database_native.dart (Android)
import 'package:sqflite/sqflite.dart';

Future<Database> getDatabase() async {
  return openDatabase(...);
}
```

---

## Android Kiosk Mode Setup

### AndroidManifest.xml

```xml
<manifest>
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>

  <application
      android:name=".MainApplication"
      android:label="StampSmart POS">

    <activity
        android:name=".MainActivity"
        android:launchMode="singleTask"
        android:screenOrientation="landscape"
        android:theme="@style/LaunchTheme"
        android:configChanges="orientation|keyboardHidden|screenSize"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize">

      <!-- Home launcher intent for kiosk mode -->
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.HOME"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>

    <!-- Boot receiver for auto-start -->
    <receiver
        android:name=".BootReceiver"
        android:enabled="true"
        android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
      </intent-filter>
    </receiver>

    <!-- Customer display activity -->
    <activity
        android:name=".CustomerDisplayActivity"
        android:theme="@style/CustomerDisplayTheme"
        android:screenOrientation="landscape"/>
  </application>
</manifest>
```

### Lock Task Mode (Kiosk)

```kotlin
// MainActivity.kt

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Enable kiosk mode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            startLockTask()
        }

        // Hide system UI
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_FULLSCREEN
        )
    }

    // Exit kiosk mode (requires admin PIN - handled in Flutter)
    fun exitKioskMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            stopLockTask()
        }
    }
}
```

---

## Update Mechanism

### Backend Version Endpoint (Already Implemented)

```javascript
// Updates service returns platform-specific download URL
{
  "latest_version": "1.0.1",
  "platforms": {
    "windows": {
      "download_url": "https://r2.example.com/releases/StampSmartPOS_Setup_1.0.1.exe",
      "file_size": "45 MB"
    },
    "android": {
      "download_url": "https://r2.example.com/releases/StampSmartPOS_1.0.1.apk",
      "file_size": "25 MB"
    }
  },
  "release_notes": [...],
  "mandatory": false
}
```

### Android APK Installation

```dart
// lib/core/services/update_service_android.dart

Future<void> installUpdate(String apkPath) async {
  if (Platform.isAndroid) {
    // Request install permission (Android 8+)
    // Use android_package_installer package or install intent
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: Uri.file(apkPath).toString(),
      type: 'application/vnd.android.package-archive',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_GRANT_READ_URI_PERMISSION],
    );
    await intent.launch();
  }
}
```

---

## Printer Configuration

### Settings Structure

```dart
enum PrinterType {
  usb,        // External USB thermal
  bluetooth,  // External Bluetooth
  network,    // Network/WiFi printer
  builtIn,    // Android kiosk built-in (80mm)
}

class PrinterSettings {
  PrinterType type;
  String? address;      // For external printers
  String? name;
  bool autoPrint;
  int paperWidth;       // 58mm or 80mm
}
```

### Built-in Printer Support

```dart
// For Android kiosk with built-in 80mm thermal printer

class BuiltInPrinterService {
  static const MethodChannel _channel = MethodChannel('com.stampsmart.pos/printer');

  Future<bool> print(List<int> escPosData) async {
    try {
      final result = await _channel.invokeMethod('print', {
        'data': escPosData,
      });
      return result == true;
    } catch (e) {
      debugPrint('Built-in printer error: $e');
      return false;
    }
  }

  Future<bool> openCashDrawer() async {
    return await _channel.invokeMethod('openDrawer');
  }
}
```

---

## Implementation Phases

### Phase 1: Platform Abstraction (Foundation)
- [ ] Create `PlatformService` interface
- [ ] Implement `PlatformWindows`
- [ ] Implement `PlatformAndroid` (basic)
- [ ] Conditional database imports
- [ ] Remove/guard `window_manager` for Android
- [ ] Test Windows still works

### Phase 2: Android Core
- [ ] Setup Android project configuration
- [ ] Implement kiosk mode (lock task)
- [ ] Implement immersive fullscreen
- [ ] APK update mechanism
- [ ] Test on emulator (landscape tablet)

### Phase 3: Customer Display
- [ ] Create `CustomerDisplayProvider`
- [ ] Create `CustomerDisplayScreen` widget
- [ ] Implement idle state with promotions
- [ ] Implement active state with cart
- [ ] Implement Android `Presentation` API
- [ ] Settings toggle for customer display

### Phase 4: Built-in Printer
- [ ] Add printer type selection in settings
- [ ] Implement built-in printer method channel
- [ ] Test ESC/POS commands on 80mm
- [ ] Auto-detect printer availability

### Phase 5: Polish & Testing
- [ ] Test on actual kiosk hardware
- [ ] Performance optimization
- [ ] Error handling for hardware failures
- [ ] Documentation

---

## Dependencies Changes

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Database - conditional
  sqflite: ^2.3.0                    # Android native
  sqflite_common_ffi: ^2.3.0         # Windows FFI

  # Window management - Windows only
  window_manager: ^0.3.7

  # Printing
  flutter_thermal_printer: ^2.0.0    # All platforms

  # Android-specific
  android_intent_plus: ^4.0.0        # For APK install
  android_package_installer: ^1.0.0  # Alternative install

  # Existing deps...
```

---

## Testing Strategy

### Emulator Testing

1. **Android Tablet Emulator**
   - Device: Pixel C or custom 15.6" tablet
   - API: 30 (Android 11)
   - Orientation: Landscape
   - Resolution: 1920x1080

2. **Dual Display Testing**
   - Use Android Studio extended controls
   - Add secondary display (1280x800)
   - Test Presentation API

### Test Commands

```bash
# Run on Android emulator
flutter run -d emulator-5554 --dart-define=ENV=uat

# Build APK for testing
flutter build apk --release --dart-define=ENV=uat

# Build for specific ABI (kiosk is ARM64)
flutter build apk --release --target-platform android-arm64 --dart-define=ENV=uat
```

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `lib/core/platform/` | NEW | Platform abstraction layer |
| `lib/core/database/database_service.dart` | MODIFY | Conditional imports |
| `lib/main.dart` | MODIFY | Platform detection, conditional init |
| `lib/features/customer_display/` | NEW | Customer-facing display |
| `lib/features/settings/settings_screen.dart` | MODIFY | Printer type, customer display toggle |
| `lib/core/services/update_service.dart` | MODIFY | Platform-specific updates |
| `android/app/src/main/AndroidManifest.xml` | MODIFY | Kiosk mode config |
| `android/app/src/main/kotlin/.../MainActivity.kt` | MODIFY | Lock task, dual display |
| `pubspec.yaml` | MODIFY | Add Android-specific deps |

---

## Notes

- **Lock Screen**: Already implemented, will be reused for kiosk security
- **Authentication**: Same flow, just fullscreen on Android
- **Offline Mode**: Works the same (SQLite)
- **API**: Same backend, no changes needed
- **Branding**: Load from settings or assets

---

## Next Session Checklist

When starting the Android kiosk implementation:

1. Read this document first
2. Start with Phase 1 (Platform Abstraction)
3. Test Windows after each change
4. Use Android tablet emulator (1920x1080)
5. Enable Developer Options > Secondary Display in emulator

---

*Document created: January 2026*
*Last updated: January 2026*
