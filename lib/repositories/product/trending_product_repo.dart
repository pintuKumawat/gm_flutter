import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/trending_product_model.dart';

/// Repository handling Trending Products network calls.
class TrendingProductRepo {
  final ApiService _apiService;

  TrendingProductRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches trending products from `/api/products/trendings?area_id={areaId}`.
  /// If the backend returns fewer than 4 trending items, supplements with
  /// active products from `/api/products` so the carousel is always full.
  Future<List<TrendingProductModel>> getTrendingProducts({int areaId = 101}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.trendingProducts,
        queryParameters: {'area_id': areaId},
      );

      List<TrendingProductModel> trendingList = [];

      if (response.data is List) {
        trendingList = (response.data as List)
            .map((item) =>
                TrendingProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawList =
            map['value'] ?? map['data'] ?? map['products'] ?? map['trendings'] ?? map['result'];
        if (rawList is List) {
          trendingList = rawList
              .map((item) =>
                  TrendingProductModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      // If backend has fewer than 4 trending products, supplement from /api/products
      if (trendingList.length < 4) {
        try {
          final allProdResponse = await _apiService.get(
            ApiEndpoints.products,
            queryParameters: {'limit': 12},
          );

          dynamic rawAllList;
          if (allProdResponse.data is List) {
            rawAllList = allProdResponse.data;
          } else if (allProdResponse.data is Map<String, dynamic>) {
            final map = allProdResponse.data as Map<String, dynamic>;
            rawAllList = map['value'] ?? map['data'] ?? map['products'] ?? map['result'];
          }

          if (rawAllList is List) {
            final moreProducts = rawAllList
                .map((item) =>
                    TrendingProductModel.fromJson(item as Map<String, dynamic>))
                .where((p) => !trendingList.any((t) => t.id == p.id))
                .toList();

            trendingList.addAll(moreProducts);
          }
        } catch (_) {
          // Silent fallback to available trending list
        }
      }

      return trendingList;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
