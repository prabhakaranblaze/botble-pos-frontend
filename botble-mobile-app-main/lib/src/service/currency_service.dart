import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:martfury/src/model/currency.dart';
import 'package:martfury/src/service/base_service.dart';

class CurrencyService extends BaseService {
  static const String selectedCurrencyKey = 'selected_currency';

  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await get('/api/v1/ecommerce/currencies');
      final List<dynamic> currenciesList = response as List<dynamic>;
      return currenciesList
          .map((currency) => Currency.fromJson(currency))
          .toList();
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<void> saveSelectedCurrency(Currency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedCurrencyKey, jsonEncode(currency.toJson()));
  }

  static Future<Currency?> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyJson = jsonDecode(
      prefs.getString(selectedCurrencyKey) ?? '{}',
    );

    if (currencyJson.isNotEmpty) {
      return Currency(
        id: currencyJson['id'],
        title: currencyJson['title'],
        symbol: currencyJson['symbol'],
        isDefault: currencyJson['isDefault'] ?? false,
        exchangeRate: currencyJson['exchangeRate'] ?? 0,
        order: currencyJson['order'] ?? 0,
        createdAt: currencyJson['createdAt'] ?? '',
        updatedAt: currencyJson['updatedAt'] ?? '',
      );
    }
    return null;
  }
}
