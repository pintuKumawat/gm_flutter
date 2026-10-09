import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';
import 'package:grahmitracus/models/product/product_detail_model.dart';

/// Repository for Product Details and Related Products API calls
class ProductDetailRepo {
  final ApiService _apiService = ApiService.instance;

  /// Fetch full product details by id or slug
  Future<ProductDetailModel?> getProductDetail(
    String idOrSlug, {
    int? areaId,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (areaId != null) queryParams['area_id'] = areaId;
      if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;

      final response = await _apiService.get(
        ApiEndpoints.productDetail(idOrSlug),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is Map<String, dynamic>) {
        return ProductDetailModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Re-throw or log
      return null;
    }
  }

  /// Fetch related products for a given category & product
  Future<List<HomeProductModel>> getRelatedProducts({
    required int categoryId,
    required int productId,
    int limit = 12,
    int offset = 0,
    int? areaId,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'category_id': categoryId,
        'product_id': productId,
        'limit': limit,
        'offset': offset,
      };
      if (areaId != null) queryParams['area_id'] = areaId;
      if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;

      final response = await _apiService.get(
        ApiEndpoints.relatedProducts,
        queryParameters: queryParams,
      );

      final dynamic resData = response.data;
      List<dynamic> items = [];

      if (resData is Map<String, dynamic>) {
        if (resData['data'] is List) {
          items = resData['data'] as List;
        }
      } else if (resData is List) {
        items = resData;
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => HomeProductModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
