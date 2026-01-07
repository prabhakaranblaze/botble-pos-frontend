import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// POS display modes
enum PosMode {
  /// Quick Select mode - Product grid on left, cart on right (default)
  quickSelect,

  /// Kiosk mode - Cart on left (scan-focused), checkout panel on right
  kiosk,
}

/// Provider for POS display mode
class PosModeProvider with ChangeNotifier {
  static const String _modeKey = 'pos_mode';

  PosMode _mode = PosMode.kiosk; // Default to Kiosk mode

  PosMode get mode => _mode;
  bool get isQuickSelect => _mode == PosMode.quickSelect;
  bool get isKiosk => _mode == PosMode.kiosk;

  PosModeProvider() {
    _loadMode();
  }

  /// Load saved mode from SharedPreferences
  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_modeKey);

      if (modeIndex != null && modeIndex < PosMode.values.length) {
        _mode = PosMode.values[modeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading POS mode: $e');
    }
  }

  /// Set mode and save to SharedPreferences
  Future<void> setMode(PosMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_modeKey, mode.index);
      debugPrint('📱 POS Mode saved: ${mode.name}');
    } catch (e) {
      debugPrint('Error saving POS mode: $e');
    }
  }

  /// Toggle between Quick Select and Kiosk modes
  Future<void> toggleMode() async {
    if (isQuickSelect) {
      await setMode(PosMode.kiosk);
    } else {
      await setMode(PosMode.quickSelect);
    }
  }

  /// Get display name for current mode
  String get modeName {
    switch (_mode) {
      case PosMode.quickSelect:
        return 'Quick Select';
      case PosMode.kiosk:
        return 'Kiosk';
    }
  }

  /// Get icon for current mode
  IconData get modeIcon {
    switch (_mode) {
      case PosMode.quickSelect:
        return Icons.grid_view_rounded;
      case PosMode.kiosk:
        return Icons.qr_code_scanner_rounded;
    }
  }
}
