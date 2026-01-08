import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/src/model/address.dart';

class AddressService extends BaseService {
  Future<List<Address>> getAddresses() async {
    try {
      final response = await get('/api/v1/ecommerce/addresses');

      final List<dynamic> addressesJson = response['data'];
      return addressesJson.map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<Address> createAddress({
    required String name,
    required String email,
    required String phone,
    required String country,
    required String state,
    required String city,
    required String address,
    required bool isDefault,
    required String zipCode,
  }) async {
    try {
      final response = await post('/api/v1/ecommerce/addresses', {
        'name': name,
        'email': email,
        'phone': phone,
        'country': country,
        'state': state,
        'city': city,
        'address': address,
        'is_default': isDefault,
        'zip_code': zipCode,
      });
      return Address.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  Future<Address> updateAddress({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String country,
    required String state,
    required String city,
    required String address,
    required bool isDefault,
    required String zipCode,
  }) async {
    try {
      final response = await put('/api/v1/ecommerce/addresses/$id', {
        'name': name,
        'email': email,
        'phone': phone,
        'country': country,
        'state': state,
        'city': city,
        'address': address,
        'is_default': isDefault,
        'zip_code': zipCode,
      });
      return Address.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await delete('/api/v1/ecommerce/addresses/$id', {});
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }
}
