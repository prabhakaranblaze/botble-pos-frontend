import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../../shared/constants/app_constants.dart';

/// Currency settings model
class CurrencySettings {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final bool isPrefix; // true = $100, false = 100Rs

  const CurrencySettings({
    this.code = 'SCR',
    this.symbol = 'Rs',
    this.name = 'Seychelles Rupee',
    this.decimalDigits = 2,
    this.isPrefix = false,
  });

  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      code: json['code'] ?? 'SCR',
      symbol: json['symbol'] ?? 'Rs',
      name: json['name'] ?? 'Seychelles Rupee',
      decimalDigits: json['decimal_digits'] ?? 2,
      isPrefix: json['is_prefix'] ?? false,
    );
  }

  /// Format amount with currency symbol
  String format(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    );
    final formattedAmount = formatter.format(amount);

    if (isPrefix) {
      return '$symbol$formattedAmount';
    } else {
      return '$formattedAmount$symbol';
    }
  }
}

/// Provider for currency settings fetched from backend
class CurrencyProvider with ChangeNotifier {
  CurrencySettings _settings = const CurrencySettings();
  double _taxRate = 0.15;
  bool _isLoaded = false;

  CurrencySettings get settings => _settings;
  double get taxRate => _taxRate;
  bool get isLoaded => _isLoaded;

  /// Format amount using current currency settings
  String format(double amount) {
    return _settings.format(amount);
  }

  /// Load currency settings from API
  Future<void> loadSettings(ApiService apiService) async {
    try {
      debugPrint('💰 CURRENCY: Loading settings from API...');

      final response = await apiService.getSettings();

      if (response != null) {
        if (response['currency'] != null) {
          _settings = CurrencySettings.fromJson(response['currency']);
          debugPrint('💰 CURRENCY: Loaded - ${_settings.code} (${_settings.symbol})');

          // Update static AppConstants for global access
          AppConstants.updateCurrency(
            code: _settings.code,
            symbol: _settings.symbol,
            decimalDigits: _settings.decimalDigits,
            isPrefix: _settings.isPrefix,
          );
        }

        if (response['tax_rate'] != null) {
          _taxRate = (response['tax_rate'] as num).toDouble();
          debugPrint('💰 CURRENCY: Tax rate - ${(_taxRate * 100).toStringAsFixed(0)}%');
        }

        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('💰 CURRENCY: Error loading settings: $e');
      // Keep default values
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Reset to defaults (for logout)
  void reset() {
    _settings = const CurrencySettings();
    _taxRate = 0.15;
    _isLoaded = false;
    notifyListeners();
  }
}
