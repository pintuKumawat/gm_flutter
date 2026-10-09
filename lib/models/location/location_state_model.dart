import 'package:grahmitracus/models/location/serviceable_location_model.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';

/// Represents the selected delivery location context across the app
class UserLocationState {
  final String type; // 'db_area' | 'saved_address' | 'detected' | 'default'
  final String displayString;
  final int? areaId;
  final String? areaName;
  final String? city;
  final String? pincode;
  final double? lat;
  final double? lng;
  final UserAddressModel? address;

  const UserLocationState({
    required this.type,
    required this.displayString,
    this.areaId,
    this.areaName,
    this.city,
    this.pincode,
    this.lat,
    this.lng,
    this.address,
  });

  /// Default fallback location matching Grahmitra core area (Sector 62, Noida)
  factory UserLocationState.defaultLocation() {
    return const UserLocationState(
      type: 'default',
      displayString: 'Sector 62, Noida',
      areaId: 101,
      areaName: 'Sector 62',
      city: 'Noida',
      pincode: '201309',
    );
  }

  /// Create state from a deliverable area chip
  factory UserLocationState.fromArea(AreaLocationModel area) {
    return UserLocationState(
      type: 'db_area',
      displayString: '${area.areaName}, ${area.cityName ?? "Noida"}',
      areaId: area.areaId,
      areaName: area.areaName,
      city: area.cityName,
      pincode: area.pincode,
    );
  }

  /// Create state from a saved user address
  factory UserLocationState.fromAddress(UserAddressModel addr) {
    return UserLocationState(
      type: 'saved_address',
      displayString: '${addr.streetAddress}, ${addr.city}',
      city: addr.city,
      pincode: addr.pincode,
      lat: addr.latitude,
      lng: addr.longitude,
      address: addr,
    );
  }
}
