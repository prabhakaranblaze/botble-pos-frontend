import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provider to track user inactivity and trigger lock screen
/// Locks the app after [lockTimeout] of no user activity
class InactivityProvider with ChangeNotifier {
  /// Duration of inactivity before locking (default 30 minutes)
  static const Duration defaultLockTimeout = Duration(minutes: 30);

  Duration _lockTimeout;
  Timer? _inactivityTimer;
  DateTime _lastActivity = DateTime.now();
  bool _isLocked = false;
  bool _isEnabled = true;

  InactivityProvider({Duration? lockTimeout})
      : _lockTimeout = lockTimeout ?? defaultLockTimeout;

  /// Whether the app is currently locked
  bool get isLocked => _isLocked;

  /// Whether inactivity tracking is enabled
  bool get isEnabled => _isEnabled;

  /// Current lock timeout duration
  Duration get lockTimeout => _lockTimeout;

  /// Time remaining until lock (for UI display)
  Duration get timeUntilLock {
    final elapsed = DateTime.now().difference(_lastActivity);
    final remaining = _lockTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Set the lock timeout duration
  void setLockTimeout(Duration timeout) {
    _lockTimeout = timeout;
    _resetTimer();
    notifyListeners();
  }

  /// Enable or disable inactivity tracking
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      _resetTimer();
    } else {
      _inactivityTimer?.cancel();
    }
    notifyListeners();
  }

  /// Call this when user interacts with the app
  void recordActivity() {
    if (!_isEnabled || _isLocked) return;
    _lastActivity = DateTime.now();
    _resetTimer();
  }

  /// Lock the app manually
  void lock() {
    _isLocked = true;
    _inactivityTimer?.cancel();
    notifyListeners();
  }

  /// Unlock the app (called after successful password verification)
  void unlock() {
    _isLocked = false;
    _lastActivity = DateTime.now();
    _resetTimer();
    notifyListeners();
  }

  /// Start tracking inactivity
  void startTracking() {
    _lastActivity = DateTime.now();
    _resetTimer();
  }

  /// Stop tracking inactivity
  void stopTracking() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    if (!_isEnabled) return;

    _inactivityTimer = Timer(_lockTimeout, () {
      if (_isEnabled && !_isLocked) {
        debugPrint('🔒 INACTIVITY: Lock timeout reached');
        lock();
      }
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

/// Widget that wraps the app to detect user activity
/// Use this at the root of your app to track all interactions
class InactivityDetector extends StatelessWidget {
  final Widget child;
  final InactivityProvider inactivityProvider;

  const InactivityDetector({
    super.key,
    required this.child,
    required this.inactivityProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => inactivityProvider.recordActivity(),
      onPointerMove: (_) => inactivityProvider.recordActivity(),
      onPointerUp: (_) => inactivityProvider.recordActivity(),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (_) => inactivityProvider.recordActivity(),
        child: child,
      ),
    );
  }
}
