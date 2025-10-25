import 'package:flutter/foundation.dart';
import '../../core/models/session.dart';
import '../../core/api/api_service.dart';
import '../../core/services/storage_service.dart';

class SessionProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  List<dynamic> _registers = []; // Changed to dynamic to handle JSON
  Map<String, dynamic>? _activeSession; // Changed to Map for JSON data
  List<Denomination> _denominations = [];

  bool _isLoading = false;
  String? _error;

  SessionProvider(this._apiService, this._storageService) {
    // Don't auto-load on init - let dashboard handle it
  }

  // Getters
  List<dynamic> get registers => _registers;
  Map<String, dynamic>? get activeSession => _activeSession;
  List<Denomination> get denominations => _denominations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!['status'] == 'open';

  /// ✅ NEW: Check for active session (used on login)
  /// Returns session data if exists, null otherwise
  Future<void> checkActiveSession() async {
    try {
      _activeSession = await _apiService.getActiveSession();

      if (_activeSession != null) {
        // Also save to local storage
        // Note: You'll need to update storage service to handle Map
        // For now, we just keep it in memory
      }
      notifyListeners();
    } catch (e) {
      // No active session or error - that's fine
      _activeSession = null;
      _error = null; // Don't treat "no session" as error
      notifyListeners();
    }
  }

  /// Load cash registers WITH session status
  Future<void> loadCashRegisters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registers = await _apiService.getCashRegisters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load denominations
  Future<void> loadDenominations({String currency = 'USD'}) async {
    try {
      _denominations = await _apiService.getDenominations(currency: currency);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Open session
  Future<bool> openSession({
    required int cashRegisterId,
    required double openingCash,
    Map<String, int>? denominations,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeSession = await _apiService.openSession(
        cashRegisterId: cashRegisterId,
        openingCash: openingCash,
        denominations: denominations,
        notes: notes,
      );

      // Save to local storage if needed
      // await _storageService.saveActiveSession(_activeSession!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Close session
  Future<bool> closeSession({
    required double closingCash,
    Map<String, int>? denominations,
    String? notes,
  }) async {
    if (_activeSession == null) {
      _error = 'No active session';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final closedSession = await _apiService.closeSession(
        sessionId: _activeSession!['id'],
        closingCash: closingCash,
        denominations: denominations,
        notes: notes,
      );

      _activeSession = closedSession;
      // await _storageService.removeActiveSession();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Calculate total from denominations
  double calculateTotal(Map<int, int> counts) {
    double total = 0;

    for (var entry in counts.entries) {
      final denom = _denominations.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => Denomination(
          id: 0,
          currency: '',
          value: 0,
          type: '',
          displayName: '',
        ),
      );
      total += denom.value * entry.value;
    }

    return total;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSession() {
    _activeSession = null;
    notifyListeners();
  }
}
