import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_exception.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/product/home_product_model.dart';

/// Response wrapper for search suggest results
class SearchResultResponse {
  final List<HomeProductModel> products;
  final bool hasMore;

  const SearchResultResponse({
    required this.products,
    required this.hasMore,
  });
}

/// Repository for handling product search queries against `/api/search/suggest`.
class SearchRepo {
  final ApiService _apiService;

  SearchRepo({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  /// Fetches suggested products and sellers matching [query].
  /// Supports pagination with [limit] and [offset], along with geo location context.
  Future<SearchResultResponse> searchSuggest({
    required String query,
    int limit = 10,
    int offset = 0,
    int areaId = 101,
    String? pincode,
    double? lat,
    double? lng,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'q': query.trim(),
        'limit': limit,
        'offset': offset,
        'area_id': areaId,
      };

      if (pincode != null && pincode.isNotEmpty) {
        queryParams['pincode'] = pincode;
      }
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;

      final response = await _apiService.get(
        ApiEndpoints.searchSuggest,
        queryParameters: queryParams,
      );

      List<HomeProductModel> productsList = [];
      bool hasMore = false;

      if (response.data is List) {
        productsList = (response.data as List)
            .map((item) =>
                HomeProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
        hasMore = productsList.length >= limit;
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic rawData = map['data'] ?? map['products'] ?? map['value'] ?? map['result'];

        if (rawData is List) {
          productsList = rawData
              .map((item) =>
                  HomeProductModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        hasMore = map['hasMore'] == true ||
            (map['has_more'] == true) ||
            productsList.length >= limit;
      }

      return SearchResultResponse(
        products: productsList,
        hasMore: hasMore,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
