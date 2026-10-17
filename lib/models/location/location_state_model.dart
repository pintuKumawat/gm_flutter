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

  /// Default unselected location when no location has been chosen
  factory UserLocationState.defaultLocation() {
    return const UserLocationState(
      type: 'default',
      displayString: '',
      areaId: 101,
      areaName: null,
      city: 'Noida',
      pincode: null,
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

  Map<String, dynamic> toJson() => {
        'type': type,
        'displayString': displayString,
        'areaId': areaId,
        'areaName': areaName,
        'city': city,
        'pincode': pincode,
        'lat': lat,
        'lng': lng,
        'address': address?.toJson(),
      };

  factory UserLocationState.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'default';
    var display = json['displayString'] as String? ?? '';
    if (type == 'default' && display == 'Sector 62, Noida') {
      display = '';
    }
    return UserLocationState(
      type: type,
      displayString: display,
      areaId: json['areaId'] as int?,
      areaName: json['areaName'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      address: json['address'] != null && json['address'] is Map
          ? UserAddressModel.fromJson(Map<String, dynamic>.from(json['address'] as Map))
          : null,
    );
  }
}

