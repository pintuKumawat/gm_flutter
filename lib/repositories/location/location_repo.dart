import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/location/serviceable_location_model.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';

/// Repository for master serviceable locations and customer addresses
class LocationRepo {
  final ApiService _apiService;

  LocationRepo({ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  /// Fetches all serviceable cities and areas from `/api/master/serviceable-locations`
  Future<List<CityLocationsModel>> getServiceableLocations() async {
    try {
      final response = await _apiService.get(ApiEndpoints.serviceableLocations);

      List<CityLocationsModel> locations = [];
      dynamic rawData = response.data;

      if (rawData is Map<String, dynamic>) {
        rawData = rawData['data'] ?? rawData['locations'] ?? rawData['value'];
      }

      if (rawData is List) {
        locations = rawData
            .map(
              (item) =>
                  CityLocationsModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return locations;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Validates a pincode against `/api/master/validate-pincode?pincode={pincode}`
  Future<AreaLocationModel?> validatePincode(String pincode) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.validatePincode,
        queryParameters: {'pincode': pincode.trim()},
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['valid'] == true && map['area'] is Map<String, dynamic>) {
          return AreaLocationModel.fromJson(
            map['area'] as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches user's saved addresses from `/api/customer/address`
  Future<List<UserAddressModel>> getSavedAddresses() async {
    try {
      final response = await _apiService.get(ApiEndpoints.customerAddress);

      List<UserAddressModel> addresses = [];
      dynamic rawData = response.data;

      if (rawData is Map<String, dynamic>) {
        rawData = rawData['addresses'] ?? rawData['data'] ?? rawData['value'];
      }

      if (rawData is List) {
        addresses = rawData
            .map(
              (item) => UserAddressModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return addresses;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Adds a new delivery address via `POST /api/customer/address`
  Future<UserAddressModel> addAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.customerAddress,
        data: addressData,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawAddr = map['address'] ?? map['data'] ?? map;
        if (rawAddr is Map<String, dynamic>) {
          return UserAddressModel.fromJson(rawAddr);
        }
      }

      return UserAddressModel.fromJson(addressData);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Updates an existing address via `PUT /api/customer/address/:id`
  Future<void> updateAddress(int id, Map<String, dynamic> addressData) async {
    try {
      await _apiService.put(
        ApiEndpoints.customerAddressUpdate(id),
        data: addressData,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Deletes an address via `DELETE /api/customer/address/delete/:id`
  Future<void> deleteAddress(int id) async {
    try {
      await _apiService.delete(ApiEndpoints.customerAddressDelete(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Sets an address as primary via `PUT /api/customer/address/:id/set-primary`
  Future<void> setPrimaryAddress(int id) async {
    try {
      await _apiService.put(ApiEndpoints.customerAddressSetPrimary(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
