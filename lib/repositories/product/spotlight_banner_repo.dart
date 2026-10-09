import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/spotlight_banner_model.dart';

/// Repository for fetching Spotlight Banners from `/api/spotlight`.
class SpotlightBannerRepo {
  final ApiService _apiService;

  SpotlightBannerRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches spotlight banners from `/api/spotlight`.
  Future<List<SpotlightBannerModel>> getSpotlightBanners({
    String displayLocation = 'home',
    int? categoryGroupId,
    int? locationId,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'display_location': displayLocation,
      };
      if (categoryGroupId != null) {
        query['category_group_id'] = categoryGroupId;
      }
      if (locationId != null) {
        query['location_id'] = locationId;
      }

      final response = await _apiService.get(
        ApiEndpoints.spotlight,
        queryParameters: query,
      );

      List<SpotlightBannerModel> bannerList = [];

      if (response.data is List) {
        bannerList = (response.data as List)
            .map((item) =>
                SpotlightBannerModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList = map['ads'] ?? map['data'] ?? map['result'];
        if (rawList is List) {
          bannerList = rawList
              .map((item) =>
                  SpotlightBannerModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      return bannerList;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
