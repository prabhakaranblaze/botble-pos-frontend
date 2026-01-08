import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/src/model/country.dart';
import 'package:martfury/src/model/state.dart';
import 'package:martfury/src/model/city.dart';

class LocationService extends BaseService {
  Future<List<Country>> getCountries() async {
    try {
      final response = await get('/api/v1/ecommerce/countries');
      final List<dynamic> countriesJson = response['data'];
      return countriesJson.map((json) => Country.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch countries: $e');
    }
  }

  Future<List<LocationState>> getStates(String countryId) async {
    try {
      final response = await get('/api/v1/ecommerce/states?country_id=$countryId');
      final List<dynamic> statesJson = response['data'];
      return statesJson.map((json) => LocationState.fromJson(json)).toList();
    } catch (e) {
      // If states endpoint doesn't exist, return empty list
      // This allows the app to gracefully handle backends without state/city support
      return [];
    }
  }

  Future<List<City>> getCities(String stateId) async {
    try {
      final response = await get('/api/v1/ecommerce/cities?state_id=$stateId');
      final List<dynamic> citiesJson = response['data'];
      return citiesJson.map((json) => City.fromJson(json)).toList();
    } catch (e) {
      // If cities endpoint doesn't exist, return empty list
      // This allows the app to gracefully handle backends without state/city support
      return [];
    }
  }

  Future<List<City>> getCitiesByCountry(String countryId) async {
    try {
      final response = await get('/api/v1/ecommerce/cities?country_id=$countryId');
      final List<dynamic> citiesJson = response['data'];
      return citiesJson.map((json) => City.fromJson(json)).toList();
    } catch (e) {
      // If cities endpoint doesn't exist, return empty list
      return [];
    }
  }

  // Helper method to find country by name (for backward compatibility)
  Future<Country?> findCountryByName(String countryName) async {
    try {
      final countries = await getCountries();
      return countries.firstWhere(
        (country) => country.name.toLowerCase() == countryName.toLowerCase(),
        orElse: () => throw Exception('Country not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to find state by name and country
  Future<LocationState?> findStateByName(String stateName, String countryId) async {
    try {
      final states = await getStates(countryId);
      return states.firstWhere(
        (state) => state.name.toLowerCase() == stateName.toLowerCase(),
        orElse: () => throw Exception('State not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to find city by name and state
  Future<City?> findCityByName(String cityName, String stateId) async {
    try {
      final cities = await getCities(stateId);
      return cities.firstWhere(
        (city) => city.name.toLowerCase() == cityName.toLowerCase(),
        orElse: () => throw Exception('City not found'),
      );
    } catch (e) {
      return null;
    }
  }
}
