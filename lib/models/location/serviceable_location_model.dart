/// Area model under a serviceable city
class AreaLocationModel {
  final int areaId;
  final String areaName;
  final String? pincode;
  final String? cityName;

  const AreaLocationModel({
    required this.areaId,
    required this.areaName,
    this.pincode,
    this.cityName,
  });

  factory AreaLocationModel.fromJson(Map<String, dynamic> json, {String? defaultCity}) {
    return AreaLocationModel(
      areaId: json['area_id'] is int
          ? json['area_id'] as int
          : int.tryParse(json['area_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      areaName: json['area_name'] as String? ?? json['name'] as String? ?? '',
      pincode: json['pincode']?.toString(),
      cityName: json['city_name'] as String? ?? json['city'] as String? ?? defaultCity,
    );
  }

  Map<String, dynamic> toJson() => {
        'area_id': areaId,
        'area_name': areaName,
        'pincode': pincode,
        'city_name': cityName,
      };
}

/// City Group with its deliverable areas from `/api/master/serviceable-locations`
class CityLocationsModel {
  final int cityId;
  final String cityName;
  final List<AreaLocationModel> areas;

  const CityLocationsModel({
    required this.cityId,
    required this.cityName,
    required this.areas,
  });

  factory CityLocationsModel.fromJson(Map<String, dynamic> json) {
    final cityName = json['city_name'] as String? ?? json['name'] as String? ?? 'City';
    final rawAreas = json['areas'];
    List<AreaLocationModel> areasList = [];

    if (rawAreas is List) {
      areasList = rawAreas
          .map((a) => AreaLocationModel.fromJson(a as Map<String, dynamic>, defaultCity: cityName))
          .toList();
    }

    return CityLocationsModel(
      cityId: json['city_id'] is int
          ? json['city_id'] as int
          : int.tryParse(json['city_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      cityName: cityName,
      areas: areasList,
    );
  }

  Map<String, dynamic> toJson() => {
        'city_id': cityId,
        'city_name': cityName,
        'areas': areas.map((a) => a.toJson()).toList(),
      };
}
