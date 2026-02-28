import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../../shared/constants/app_constants.dart';

/// Currency settings model
class CurrencySettings {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final bool isPrefix;
  final bool addSpace;
  final String thousandsSeparator;
  final String decimalSeparator;

  const CurrencySettings({
    this.code = 'SCR',
    this.symbol = 'SCR',
    this.name = 'Seychelles Rupee',
    this.decimalDigits = 2,
    this.isPrefix = false,
    this.addSpace = true,
    this.thousandsSeparator = ',',
    this.decimalSeparator = '.',
  });

  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      code: json['code'] ?? 'SCR',
      symbol: json['symbol'] ?? 'SCR',
      name: json['name'] ?? 'Seychelles Rupee',
      decimalDigits: json['decimal_digits'] ?? 2,
      isPrefix: json['is_prefix'] ?? false,
      addSpace: json['add_space'] ?? true,
      thousandsSeparator: json['thousands_separator'] ?? ',',
      decimalSeparator: json['decimal_separator'] ?? '.',
    );
  }

  /// Format amount with currency symbol
  String format(double amount) {
    final decimals = decimalDigits;

    // Format number manually with configured separators
    final parts = amount.toStringAsFixed(decimals).split('.');
    final intPart = _addThousandsSeparator(parts[0], thousandsSeparator);
    final decPart = parts.length > 1 ? parts[1] : '';
    final formatted = decPart.isNotEmpty
        ? '$intPart$decimalSeparator$decPart'
        : intPart;

    final space = addSpace ? ' ' : '';
    if (isPrefix) {
      return '$symbol$space$formatted';
    } else {
      return '$formatted$space$symbol';
    }
  }

  static String _addThousandsSeparator(String intPart, String separator) {
    if (intPart.length <= 3) return intPart;

    final isNegative = intPart.startsWith('-');
    final digits = isNegative ? intPart.substring(1) : intPart;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }

    return isNegative ? '-${buffer.toString()}' : buffer.toString();
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
          debugPrint('💰 CURRENCY: Loaded - ${_settings.code} (${_settings.symbol}) space=${_settings.addSpace}');

          // Update static AppConstants for global access
          AppConstants.updateCurrency(
            code: _settings.code,
            symbol: _settings.symbol,
            decimalDigits: _settings.decimalDigits,
            isPrefix: _settings.isPrefix,
            addSpace: _settings.addSpace,
            thousandsSeparator: _settings.thousandsSeparator,
            decimalSeparator: _settings.decimalSeparator,
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
