/// Model representing a customer's saved delivery address
class UserAddressModel {
  final int id;
  final int? userId;
  final String streetAddress;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final bool isPrimary;
  final bool isActive;
  final String addressType; // 'home' | 'work' | 'other'
  final double? latitude;
  final double? longitude;
  final String? receiverName;
  final String? receiverPhone;
  final bool isForOther;

  const UserAddressModel({
    required this.id,
    this.userId,
    required this.streetAddress,
    this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.isPrimary = false,
    this.isActive = true,
    this.addressType = 'home',
    this.latitude,
    this.longitude,
    this.receiverName,
    this.receiverPhone,
    this.isForOther = false,
  });

  /// Full formatted address string
  String get formattedAddress {
    final parts = [streetAddress, landmark, city, state, pincode];
    return parts.where((p) => p != null && p.trim().isNotEmpty).join(', ');
  }

  /// Compact one-line display label
  String get displayTitle {
    final type = addressType.isNotEmpty ? addressType.toUpperCase() : 'HOME';
    return type;
  }

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? ''),
      streetAddress: json['street_address'] as String? ?? json['streetAddress'] as String? ?? '',
      landmark: json['landmark'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country'] as String? ?? 'India',
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == null,
      addressType: (json['address_type'] as String? ?? 'home').toLowerCase(),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      receiverName: json['receiver_name'] as String?,
      receiverPhone: json['receiver_phone'] as String?,
      isForOther: json['is_for_other'] == 1 || json['is_for_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'street_address': streetAddress,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
        'country': country,
        'is_primary': isPrimary ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'address_type': addressType,
        'latitude': latitude,
        'longitude': longitude,
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'is_for_other': isForOther ? 1 : 0,
      };
}
