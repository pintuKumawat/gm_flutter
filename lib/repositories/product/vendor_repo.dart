import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/vendor_model.dart';

/// Repository for fetching vendor shops and store storefront data
class VendorRepo {
  final ApiService _apiService;

  VendorRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches approved and active nearby vendors
  Future<List<VendorModel>> getVendors({int? areaId}) async {
    try {
      final Map<String, dynamic> query = {};
      if (areaId != null && areaId > 0) {
        query['area_id'] = areaId;
      }

      final response = await _apiService.get(
        ApiEndpoints.vendors,
        queryParameters: query.isNotEmpty ? query : null,
      );

      List<dynamic> list = [];
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map && response.data['vendors'] is List) {
        list = response.data['vendors'] as List;
      } else if (response.data is Map && response.data['data'] is List) {
        list = response.data['data'] as List;
      }

      // If location filter produced an empty list, fallback to all active vendors
      if (list.isEmpty && query.isNotEmpty) {
        final fallbackResponse = await _apiService.get(ApiEndpoints.vendors);
        if (fallbackResponse.data is List) {
          list = fallbackResponse.data as List;
        } else if (fallbackResponse.data is Map &&
            fallbackResponse.data['vendors'] is List) {
          list = fallbackResponse.data['vendors'] as List;
        } else if (fallbackResponse.data is Map &&
            fallbackResponse.data['data'] is List) {
          list = fallbackResponse.data['data'] as List;
        }
      }

      return list
          .map((item) =>
              VendorModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetches store profile, categories, and products for a specific vendor via `GET /api/store/:slug`
  Future<StoreDetailResponse> getStoreDetails({
    required String slug,
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? filter,
    int? areaId,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'page': page,
        'limit': limit,
      };
      if (category != null && category.trim().isNotEmpty) {
        query['category'] = category.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (filter != null && filter.trim().isNotEmpty) {
        query['filter'] = filter.trim();
      }
      if (areaId != null && areaId > 0) {
        query['area_id'] = areaId;
      }

      final response = await _apiService.get(
        ApiEndpoints.storeDetail(slug),
        queryParameters: query,
      );

      if (response.data is Map<String, dynamic>) {
        return StoreDetailResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else if (response.data is Map) {
        return StoreDetailResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }

      throw ApiException(message: 'Invalid store response from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
