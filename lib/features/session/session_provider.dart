import 'package:flutter/foundation.dart';
import '../../core/models/session.dart';
import '../../core/api/api_service.dart';
import '../../core/services/storage_service.dart';

class SessionProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  List<CashRegister> _registers = [];
  PosSession? _activeSession;
  List<Denomination> _denominations = [];

  bool _isLoading = false;
  String? _error;

  SessionProvider(this._apiService, this._storageService) {
    _loadActiveSession();
  }

  // Getters
  List<CashRegister> get registers => _registers;
  PosSession? get activeSession => _activeSession;
  List<Denomination> get denominations => _denominations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _activeSession != null && _activeSession!.isOpen;

  Future<void> _loadActiveSession() async {
    try {
      _activeSession = await _apiService.getActiveSession();
      if (_activeSession != null) {
        await _storageService.saveActiveSession(_activeSession!);
      }
      notifyListeners();
    } catch (e) {
      // Try to load from storage
      _activeSession = await _storageService.getActiveSession();
      notifyListeners();
    }
  }

  // Load cash registers
  Future<void> loadCashRegisters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registers = await _apiService.getCashRegisters();
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

      await _storageService.saveActiveSession(_activeSession!);

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
        sessionId: _activeSession!.id,
        closingCash: closingCash,
        denominations: denominations,
        notes: notes,
      );

      _activeSession = closedSession;
      await _storageService.removeActiveSession();

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
