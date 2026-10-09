import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/category_group_products_model.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';

/// Repository for fetching Category Groups with Products (`/api/category-groups-products`)
/// and Products by Category Group (`/api/products?categoryGroupSlug=...`).
class HomeGroupProductsRepo {
  final ApiService _apiService;

  HomeGroupProductsRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches category groups along with their products from `/api/category-groups-products`.
  Future<List<CategoryGroupProductsModel>> getCategoryGroupsProducts({
    int? areaId,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (areaId != null) query['area_id'] = areaId;
      if (pincode != null) query['pincode'] = pincode;
      if (lat != null) query['lat'] = lat;
      if (lng != null) query['lng'] = lng;

      final response = await _apiService.get(
        ApiEndpoints.categoryGroupsProducts,
        queryParameters: query.isNotEmpty ? query : null,
      );

      List<CategoryGroupProductsModel> groupsList = [];

      if (response.data is List) {
        groupsList = (response.data as List)
            .map((item) =>
                CategoryGroupProductsModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList = map['data'] ?? map['groups'] ?? map['result'];
        if (rawList is List) {
          groupsList = rawList
              .map((item) =>
                  CategoryGroupProductsModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      return groupsList;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetches products for a specific category group slug from `/api/products`.
  Future<List<HomeProductModel>> getProductsByGroupSlug({
    required String slug,
    int limit = 12,
    int offset = 0,
    int? areaId,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'categoryGroupSlug': slug,
        'limit': limit,
        'offset': offset,
      };
      if (areaId != null) query['area_id'] = areaId;

      final response = await _apiService.get(
        ApiEndpoints.products,
        queryParameters: query,
      );

      List<HomeProductModel> productList = [];

      if (response.data is List) {
        productList = (response.data as List)
            .map((item) => HomeProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList = map['data'] ?? map['products'] ?? map['result'];
        if (rawList is List) {
          productList = rawList
              .map((item) =>
                  HomeProductModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      return productList;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
